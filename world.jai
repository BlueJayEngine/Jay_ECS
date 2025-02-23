#add_context world_ptr: *void;

World :: struct (systems: [$SYS_COUNT]Type) {

    size :: component_registry.count;

    archetypes: [..] Archetype(component_registry);
    entities: [..] Entity_State(component_registry);
    thumbstones: [..] s64;

    dirty_archs: [..] *Archetype(component_registry);

    component_registry :: #run -> []Type {

        result: [..]Type;
        
        for system_type: systems {
            
            params := (cast(*Type_Info_Struct)system_type).specified_parameters;

            proc_type := params[1].type;

            collect_arg_types(proc_type, *result);
        }

        log("%", result);

        return result;
    }

    system_signs :: #run -> []Signature(component_registry) {
        result: [SYS_COUNT]Signature(component_registry);
        
        for system_type, index: systems {
            
            params := (cast(*Type_Info_Struct)system_type).specified_parameters;
            proc_type := params[1].type;

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

    _progress_impl :: (world: $WT/World, delta_time: float64, condition: u64) {
        log("% - %", systems[0].run_if, condition);
        #insert -> string {
            builder: String_Builder;

            for system_type, index: systems {
                handle_system(system_type, index, component_registry, *builder);
            }

            return builder_to_string(*builder);
        }
    }
}

progress :: inline (world: $WT/World, delta_time: float64, condition: $CT = 0) #modify {
    ct_info := cast(*Type_Info)CT;

    if ct_info.runtime_size != 8 then return false, "Condition must be 64bit enum flag";

    if ct_info.type == {
        case .INTEGER; {
            return true;
        }
        case .ENUM; {
            return (cast(*Type_Info_Enum)ct_info).enum_type_flags & Enum_Type_Flags.FLAGS == Enum_Type_Flags.FLAGS, "Condition must be 64bit enum flag";
        }
    }

    return false, "Condition must be 64bit enum flag";
} {
    
    procs :: Entity_Procs.{
        new_entity = inline (components: ..Any) -> Entity {
            return new_entity(cast(*WT)context.world_ptr, components);
        },
        set = inline (entity: Entity, components: ..Any) {
            set(cast(*WT)context.world_ptr, entity, components);
        },
        erase = inline (entity: Entity, types: ..Type) {
            erase(cast(*WT)context.world_ptr, entity, types);
        },
        destroy = inline (entity: Entity) {
            destroy(cast(*WT)context.world_ptr, entity);
        },
        dump = inline (entity: Entity) {
            dump(cast(*WT)context.world_ptr, entity);
        },
    };
    
    WT._progress_impl(world, delta_time, xx condition,, ent_procs = procs, world_ptr = *world);
}

cleanup :: (world: $WT/World) {
    for arch: world.dirty_archs {
        while arch.to_destroy.count > 0 {
            instance_destroy(arch, pop(*arch.to_destroy));
            if arch.count <= 0 {
                arch_free(arch);
                for world.archetypes {
                    if it == arch.* then remove it;
                }
            }
        }

        remove arch;
    }
}

dump :: (world: $WT/World) {
    builder: String_Builder;

    init_string_builder(*builder,, temp);

    print_to_builder(*builder, "World_%:\n", cast(s64)*world);

    for * world.archetypes dump(it, *builder);

    log("%", builder_to_string(*builder,, temp));
}

free :: (world: $WT/World) {
    for arch: world.archetypes {
        arch_free(arch);
    }
    array_free(world.archetypes);
    array_free(world.entities);
    array_free(world.thumbstones);
}