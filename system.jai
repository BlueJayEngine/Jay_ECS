// System is a poly struct that wraps procedures and also may store condition enum flag value. 
// TODO: Add run_if validation

System :: struct(proc: $PT, run_if: u64 = 0) {}

// As delta_time is part of system handling it's here too

Delta_Time :: float64;

#add_context jay_delta_time: Delta_Time;

delta_time :: inline () -> Delta_Time {
    return context.jay_delta_time;
}

// The thing that generates system handlers. May be rewritten in unexpected ways
handle_system :: (system_type: Type, index: s64, component_registry: []Type, builder: *String_Builder) {
    params := (cast(*Type_Info_Struct)system_type).specified_parameters;
    proc_type := params[1].type;

    per_entity := false;
    batched := false;
    non_batched_components := false;
    batch_target: s64 = 4;
    call_strings: [..]string;
    cast_strings: [..]string;

    arg_types := (cast(*Type_Info_Procedure)proc_type).argument_types;

    print_to_builder(builder, "if condition & systems[%].run_if { // Handling %\n", index, index, system_type);
    print_to_builder(builder, "    sys_proc :: systems[%].proc;\n", index);

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

    if batched && non_batched_components {
        log_error("System % mixes batched and non-batched component arguments.", system_type);
        return;
    }

    if per_entity {
        print_to_builder(builder, "    sign :: #run sign_system(component_registry, systems[%].PT);\n", index);
        print_to_builder(builder, "    for *arch: world.archetypes {\n");
        print_to_builder(builder, "        if match(arch.signature, sign) {\n");
        print_to_builder(builder, "%\n", join(..cast_strings, ""));
        if batched {
            print_to_builder(builder, "            batch_index: s64 = 0;\n");
            print_to_builder(builder, "            batch_target: s64 = %;\n", batch_target);
            print_to_builder(builder, "            while batch_index < arch.count {\n");
            print_to_builder(builder, "                batch_size := arch.count - batch_index;\n");
            print_to_builder(builder, "                if batch_size > batch_target batch_size = batch_target;\n");
            print_to_builder(builder, "                sys_proc(%);\n", join(..call_strings, ", "));
            print_to_builder(builder, "                batch_index += batch_target;\n");
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
                if arr_info.array_type == .VIEW {
                    arg = (cast(*Type)*arr_info.element_type).*;
                }
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
    if arg_type == {
        case Entity; {
                return tprint("owner"), "", true, false;
            }

        case Delta_Time; {
                return tprint("delta_time"), "", false, false;
            }
    }

    arg_type_info := cast(*Type_Info)arg_type;

    if arg_type_info.type == .STRUCT {
        struct_info := (cast(*Type_Info_Struct)arg_type_info);
        src_info := struct_info.polymorph_source_struct;

        if src_info == type_info(Query()).polymorph_source_struct {
            struct_index := cast(u64)struct_info;
            return tprint("query_%", struct_index), tprint("\tquery_%: #run -> Type { q_index : u64 = %; return (cast(*Type) *q_index).*; }\n\tinit(world, *query_%);", struct_index, struct_index, struct_index), false, false;
        }
    }

    if arg_type_info.type == .ARRAY {
        arr_info := cast(*Type_Info_Array)arg_type_info;
        if arr_info.array_type == .VIEW {
            target := (cast(*Type)*arr_info.element_type).*;
            registred, arg_index := array_find(reg, target);
            if !registred log_error("% is not registred!", target);
            return tprint("([]component_registry[%]).{ data = arg_%_base + batch_index, count = batch_size }", arg_index, arg_index), tprint("            arg_%_base := cast(*component_registry[%])arch.storage[%];\n", arg_index, arg_index, arg_index), true, true;
        }
    }

    if arg_type_info.type == .POINTER {
        ptr_target := (cast(*Type)*(cast(*Type_Info_Pointer)arg_type_info).pointer_to).*;
        registred, arg_index := array_find(reg, ptr_target);
        if !registred log_error("% is not registred!", ptr_target);
        return tprint("*arg_%[inst_index]", arg_index), tprint("            arg_% := cast(*component_registry[%])arch.storage[%];\n", arg_index, arg_index, arg_index), true, false;
    }

    registred, arg_index := array_find(reg, arg_type);
    if !registred log_error("% is not registred!", arg_type);
    return tprint("arg_%[inst_index]", arg_index), tprint("            arg_% := cast(*component_registry[%])arch.storage[%];\n", arg_index, arg_index, arg_index), true, false;
}
