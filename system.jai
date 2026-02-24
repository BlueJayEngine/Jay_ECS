// --- Lightweight entry for compile-time AST walking -------------------------

Proc_Info :: struct {
    name:   string;
    notes:  [] string;
}

// Walk #code,typed AST and collect procedure names + notes
collect_proc_info :: (code: Code) -> [] Proc_Info {
    _, exprs := compiler_get_nodes(code);

    entries: [..] Proc_Info;

    for exprs {
        if it.kind != .IDENT continue;
        ident := cast(*Code_Ident) it;
        if !ident.resolved_declaration continue;
        decl := ident.resolved_declaration;
        if !decl.expression continue;
        if decl.expression.kind != .PROCEDURE_HEADER continue;

        entry: Proc_Info;
        entry.name = copy_string(ident.name);

        note_texts: [..] string;
        for decl.notes array_add(*note_texts, copy_string(it.text));
        entry.notes = note_texts;

        array_add(*entries, entry);
    }

    return entries;
}

// --- Helpers ----------------------------------------------------------------

build_sorted_order :: (entries: [] Proc_Info) -> [] s64 {
    nodes := NewArray(entries.count, Node_Info(string));
    for entries nodes[it_index].value = it.name;

    for entry, node_i: entries {
        for note: entry.notes {
            if starts_with(note, "before:") {
                target_name := slice(note, 7, note.count - 7);
                found, target_i := find_node(nodes, target_name);
                assert(found, "Unknown system '%' in @before: note on '%'", target_name, entry.name);

                if !array_find(nodes[node_i].edges, target_i) {
                    array_add(*nodes[node_i].edges, target_i);
                    nodes[target_i].heat += 1;
                }
            }
            if starts_with(note, "after:") {
                target_name := slice(note, 6, note.count - 6);
                found, target_i := find_node(nodes, target_name);
                assert(found, "Unknown system '%' in @after: note on '%'", target_name, entry.name);

                if !array_find(nodes[target_i].edges, node_i) {
                    array_add(*nodes[target_i].edges, node_i);
                    nodes[node_i].heat += 1;
                }
            }
        }
    }

    return topo_sort(nodes);
}




starts_with :: inline (s: string, prefix: string) -> bool {
    if s.count < prefix.count return false;
    for index: 0..prefix.count-1 {
        if s[index] != prefix[index] return false;
    }
    return true;
}

get_bach_size :: inline (notes: []*Code_Note) -> s64 {
    for notes {
        if starts_with(it.text, "batch_size:") {
            value_string := slice(it.text, 11, it.text.count - 11);
            size_new, success := parse_int(*value_string, s64);
            assert(success, "Unknown value '%' in @batch_size", value_string);
            return size_new;
        }
    }

    return 4;
}

get_without_names :: (notes: []*Code_Note) -> []string {
    result: [..]string;
    for notes {
        if starts_with(it.text, "without:") {
            name := slice(it.text, 8, it.text.count - 8);
            array_add(*result, copy_string(name));
        }
    }
    return result;
}

// Build a culling signature from @without: type names resolved against the registry
sign_system_culling :: ($reg: [$SIZE]Type, $without_names: []string) -> Signature(reg) {
    result: Signature(reg);

    for name: without_names {
        found := false;
        for comp, c_index: reg {
            comp_info := cast(*Type_Info_Struct)cast(*Type_Info)comp;
            if comp_info.name == name {
                result.base[c_index >> 6] |= (1 << (c_index & 63));
                found = true;
                break;
            }
        }
        assert(found, "Unknown component '%' in @without: note. Not found in component registry.", name);
    }

    return result;
}

handle_system :: (proc_code: Code, index: s64, component_registry: []Type, builder: *String_Builder) {
    per_entity := false;
    batched := false;
    non_batched_components := false;
    batch_size: s64 = 4;
    call_strings: [..]string;
    cast_strings: [..]string;
    
    proc_info, notes := code_proc_type(proc_code);
    root := compiler_get_nodes(proc_code);

    arg_types := proc_info.argument_types;
    batch_size = get_bach_size(notes);

    print_to_builder(builder, "{ // Handling %\n", index);
    print_to_builder(builder, "    sys_proc :: #insert systems[%];\n", index);

    

    for arg: arg_types {
        arg_type := (cast(*Type)*arg).*;
        call, casting, per_ent, per_batch := get_arg_template(arg_type, component_registry);
        array_add(*call_strings, call);
        array_add(*cast_strings, casting);
        per_entity |= per_ent;
        batched |= per_batch;
        if per_ent && !per_batch {
            non_batched_components = true;
        }
    }

    assert(!(batched && non_batched_components), "System % mixes batched and non-batched component arguments.", index);

    without_names := get_without_names(notes);
    has_culling := without_names.count > 0;

    if per_entity {
        print_to_builder(builder, "    sign :: #run sign_system(component_registry, type_of(sys_proc));\n", index);

        if has_culling {
            // Emit the without names as a compile-time constant array
            print_to_builder(builder, "    culling_sign :: #run sign_system_culling(component_registry, string.[");
            for name, i: without_names {
                if i > 0 print_to_builder(builder, ", ");
                print_to_builder(builder, "\"%\"", name);
            }
            print_to_builder(builder, "]);\n");
        }

        print_to_builder(builder, "    for *arch: world.archetypes {\n");

        if has_culling {
            print_to_builder(builder, "        if match(arch.signature, sign) && !overlaps(arch.signature, culling_sign) {\n");
        } else {
            print_to_builder(builder, "        if match(arch.signature, sign) {\n");
        }
        print_to_builder(builder, "%\n", join(..cast_strings, ""));
        if batched {
            print_to_builder(builder, "            batch_index: s64 = 0;\n");
            print_to_builder(builder, "            batch_size: s64 = %;\n", batch_size);
            print_to_builder(builder, "            owners: []Entity;\n");
            print_to_builder(builder, "            while batch_index < arch.count {\n");
            print_to_builder(builder, "                remaining := min(batch_size, arch.count - batch_index);\n");
            print_to_builder(builder, "                owners.data = *arch.owners[batch_index];\n");
            print_to_builder(builder, "                owners.count = remaining;\n");
            print_to_builder(builder, "                sys_proc(%);\n", join(..call_strings, ", "));
            print_to_builder(builder, "                batch_index += batch_size;\n");
            print_to_builder(builder, "            }\n");
        }
        else {
            print_to_builder(builder, "            for owner, inst_index: arch.owners {\n");
            print_to_builder(builder, "                sys_proc(%);\n", join(..call_strings, ", "));
            print_to_builder(builder, "            }\n");
        }
        print_to_builder(builder, "        }\n");
        print_to_builder(builder, "        cleanup(*world, arch);\n");
        print_to_builder(builder, "    }\n");
    }
    else {
        print_to_builder(builder, "%\n", join(..cast_strings, ""));
        print_to_builder(builder, "    sys_proc(%);\n", join(..call_strings, ", "));
    }
    print_to_builder(builder, "}\n");
}

Argument_Collection_Flags :: enum_flags {
    INC_QUERIES;
    PRS_QUERIES;
}

collect_arg_types :: (proc_type: *Type_Info, result: *[..]Type, flags: Argument_Collection_Flags = 0) {
    handle_types((cast(*Type_Info_Procedure)proc_type).argument_types, result, flags);
}

handle_types :: (types: []*Type_Info, result: *[..]Type, flags: Argument_Collection_Flags) {
    for arg_info: types {
        arg := (cast(*Type)*arg_info).*;

        if arg_info.type == {
            case .POINTER; {
                ptr_type := (cast(*Type_Info_Pointer)arg_info).pointer_to;
                arg = (cast(*Type)*ptr_type).*;
            }

            case .STRUCT; {
                struct_info := (cast(*Type_Info_Struct)arg_info);
                src_info := struct_info.polymorph_source_struct;

                if src_info == type_info(Query()).polymorph_source_struct {
                    if flags & .PRS_QUERIES {
                        q_types: []*Type_Info;
                        for param, q_index: struct_info.specified_parameters {
                            if param.name == "components" {
                                q_types.count = (cast(*Type_Info_Array)param.type).array_count;
                                q_types.data = xx (struct_info.constant_storage.data + param.offset_into_constant_storage);
                            }
                        }
                        handle_types(q_types, result, 0);
                        continue;
                    }

                    if !(flags & .INC_QUERIES) continue;
                }
            }

            case .ARRAY; {
                arr_info := (cast(*Type_Info_Array)arg_info);
                assert(arr_info.array_type == .VIEW, "Only array views are supported as system component arguments. Got %.", arg_info);
                arg = (cast(*Type)*arr_info.element_type).*;
            }
        }

        if arg == Entity continue;

        array_add_if_unique(result, arg);
    }
}

// Generate system signature
sign_system :: ($reg: [$SIZE]Type, $system: Type) -> Signature(reg) {
    proc_types :: #run -> []Type {
        res: [..]Type;
        collect_arg_types(cast(*Type_Info)system, *res);
        return res;
    }

    return sign(reg, proc_types);
}

get_arg_template :: (arg_type: Type, reg: []Type) -> (call_str: string, cast_str: string, per_ent: bool, batched: bool) {
    if arg_type == Entity then return "owner", "", true, false;

    arg_type_info := cast(*Type_Info)arg_type;

    if arg_type_info.type == .STRUCT {
        struct_info := (cast(*Type_Info_Struct)arg_type_info);
        src_info := struct_info.polymorph_source_struct;

        if src_info == type_info(Query()).polymorph_source_struct {
            struct_index := cast(u64)struct_info;
            return tprint("query_%", struct_index), tprint("    query_%: #run -> Type { q_index : u64 = %; return (cast(*Type) *q_index).*; }\n\tinit(world, *query_%);", struct_index, struct_index, struct_index), false, false;
        }
    }

    if arg_type_info.type == .ARRAY {
        arr_info := cast(*Type_Info_Array)arg_type_info;
        assert(arr_info.array_type == .VIEW, "Only array views are supported as batched component arguments. Got %.", arg_type_info);
        target := (cast(*Type)*arr_info.element_type).*;

        if target == Entity {
            return "owners", "", true, true;
        }

        registred, arg_index := array_find(reg, target);
        assert(registred, "% is not registered!", target);
        return tprint("([]component_registry[%]).{ data = arg_%_base + batch_index, count = remaining }", arg_index, arg_index), tprint("            arg_%_base := cast(*component_registry[%])arch.storage[%];\n", arg_index, arg_index, arg_index), true, true;
    }

    if arg_type_info.type == .POINTER {
        ptr_target := (cast(*Type)*(cast(*Type_Info_Pointer)arg_type_info).pointer_to).*;
        registred, arg_index := array_find(reg, ptr_target);
        assert(registred, "% is not registered!", ptr_target);
        return tprint("*arg_%[inst_index]", arg_index), tprint("            arg_% := cast(*component_registry[%])arch.storage[%];\n", arg_index, arg_index, arg_index), true, false;
    }

    registred, arg_index := array_find(reg, arg_type);
    assert(registred, "% is not registered!", arg_type);
    return tprint("arg_%[inst_index]", arg_index), tprint("            arg_% := cast(*component_registry[%])arch.storage[%];\n", arg_index, arg_index, arg_index), true, false;
}
