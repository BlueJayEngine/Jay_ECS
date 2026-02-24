#add_context world_ptr: *void;

#add_context __jay_delta_time: float64;

#if DEBUG {
    #add_context __jay_system_timings: Table(string, float64);
}

delta_time :: () -> float64 {
    return context.__jay_delta_time;
}

#if DEBUG {
    system_timings :: inline () -> *Table(string, float64) {
        return *context.__jay_system_timings;
    }
}

// The World represents the game state.
// Systems are bare procedures passed via #code,typed block.
// Ordering is controlled by @before:name / @after:name notes on the procedures.
//
// Basic example:
//
//      world: World(Code.[tick, render]);
//
// Where tick and render are procedures defined with optional ordering notes:
//      tick :: (entity: Entity) { ... }
//      render :: (meshes: []Mesh) { ... } @after:tick
//
// Systems can't be added/removed at runtime.

World :: struct ($systems: [$SYS_COUNT]Code) {

    entities: [..] Entity_State(component_registry);
    thumbstones: [..] u32;

    archetypes: [..] Archetype(component_registry);
    dirty_archs: [..] *Archetype(component_registry);

    component_registry :: #run -> []Type {

        result: [..]Type;
        for system_code: systems {
            proc_type := code_proc_type(system_code);
            collect_arg_types(proc_type, *result, .PRS_QUERIES);
        }

        log("World component registry is: %", result);

        return result;
    }

    system_signs :: #run -> [SYS_COUNT]Signature(component_registry) {
        result: [SYS_COUNT]Signature(component_registry);
        
        for system_code, index: systems {

            proc_type := code_proc_type(system_code);
            
            types: [..]Type;
            collect_arg_types(proc_type, *types);

            sign: Signature(component_registry);

            for type: types {
                exists, index := array_find(component_registry, type);
                sign.base[index >> 6] |= (1 << (index & 63)); 
            }

            result[index] = sign;
        }

        return result;
    }

    _progress_impl :: (world: World) {
        #insert -> string {
            builder: String_Builder;

            // Collect proc info from each system Code block
            entries: [SYS_COUNT]Proc_Info;
            for system_code, i: systems {
                _, notes := code_proc_type(system_code);
                root := compiler_get_nodes(system_code);
                ident := cast(*Code_Ident) root;
                entries[i].name = copy_string(ident.name);

                note_strings: [..] string;
                for notes array_add(*note_strings, copy_string(it.text));
                entries[i].notes = note_strings;
            }

            sorted := build_sorted_order(entries);

            for sorted {
                #if DEBUG {
                    print_to_builder(*builder, "{\n");
                    print_to_builder(*builder, "    __sys_start := current_time_monotonic();\n");
                }

                handle_system(systems[it], xx it, component_registry, *builder);

                #if DEBUG {
                    sys_name := entries[it].name;
                    print_to_builder(*builder, "    __sys_elapsed := to_float64_seconds(current_time_monotonic() - __sys_start) * 1_000_000.0;\n");
                    print_to_builder(*builder, "    table_set(*context.__jay_system_timings, \"%\", __sys_elapsed);\n", sys_name);
                    print_to_builder(*builder, "}\n");
                }
            }

            return builder_to_string(*builder);
        }
    }
}

code_proc_type :: (code: Code) -> *Type_Info_Procedure, []*Code_Note {
    root := compiler_get_nodes(code);
    assert(root != null, "Procedure root is not recognized");
    assert(root.kind == .IDENT, "Procedure is not identifier");
    ident := cast(*Code_Ident) root;
    t_info := ident.type;
    assert(t_info.type == .PROCEDURE, "The type is not procedure");
    proc_type := cast(*Type_Info_Procedure)t_info;

    return proc_type, ident.resolved_declaration.notes;
}

// To keep your world spinning you need to call progress function.
// No more condition flags — ordering is handled by @before:/@after: notes.

progress :: inline (world: *World, delta_time: float64) {

    WT :: type_of(world);

    procs :: Entity_Procs.{
        new_entity = (components: ..Any) -> Entity {
            return inline new_entity(cast(WT)context.world_ptr, components);
        },
        get = (entity: Entity, component: Type) -> *void {
            return inline get(cast(WT)context.world_ptr, entity, component);
        },
        set = (entity: Entity, components: ..Any) {
            inline set(cast(WT)context.world_ptr, entity, components);
        },
        erase = (entity: Entity, types: ..Type) {
            inline erase(cast(WT)context.world_ptr, entity, types);
        },
        destroy = (entity: Entity) {
            inline destroy(cast(WT)context.world_ptr, entity);
        },
        dump = (entity: Entity) {
            inline dump(cast(WT)context.world_ptr, entity);
        },
    };

    WT._progress_impl(world,, ent_procs = procs, world_ptr = world, __jay_delta_time = delta_time);
}

cleanup :: inline (world: *World, arch: *Archetype) {
    while arch.to_destroy.count > 0 {
        instance_destroy(world, arch, pop(*arch.to_destroy));
        if arch.count <= 0 {
            arch_free(arch);
            for world.archetypes {
                if it == arch.* then remove it;
            }
        }
    }
}

// Print world state into logs
dump :: (world: World) {
    builder: String_Builder;

    init_string_builder(*builder,, temp);

    print_to_builder(*builder, "World_%:\n", reinterp(s64, *world));

    for * world.archetypes dump(it, *builder);

    log("%", builder_to_string(*builder,, temp));
}

// clear everything
free :: (world: World) {
    for arch: world.archetypes {
        arch_free(arch);
    }
    array_free(world.archetypes);
    array_free(world.entities);
    array_free(world.thumbstones);
}
