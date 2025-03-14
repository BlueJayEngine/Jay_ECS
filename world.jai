#add_context world_ptr: *void;
#add_context compo: []Type;


// The World represents the game state.  
// It needs to know which systems you'll use.  
// Systems are just procedures wrapped in a System poly struct (see system.jai).  
//  
// Basic example:  
//  
//      world: World(systems = .[  
//          System(tick),   // e.g., tick :: (entity: Entity) { ... }  
//      ]);  
//  
// Systems can't be added/removed at runtime, so they all are conditional.  
// Also they just run one after another, no analysis or parallelisation.  
// This part of the ECS is still evolving, so it's a little messy.

World :: struct (systems: [$SYS_COUNT]Type) {

    entities: [..] Entity_State(component_registry);
    thumbstones: [..] s64;

    archetypes: [..] Archetype(component_registry);
    dirty_archs: [..] *Archetype(component_registry);

    component_registry :: #run -> []Type {

        result: [..]Type;
        
        for system_type: systems {
            
            params := (cast(*Type_Info_Struct)system_type).specified_parameters;

            proc_type := params[1].type;

            collect_arg_types(proc_type, *result, .PRS_QUERIES);
        }

        log("World component registry is: %", result);

        return result;
    }

    system_signs :: #run -> [SYS_COUNT]Signature(component_registry) {
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

    _progress_impl :: (world: World, delta_time: float64, condition: u64) {
        #insert -> string {
            builder: String_Builder;

            for system_type, index: systems {
                handle_system(system_type, index, component_registry, *builder);
            }

            return builder_to_string(*builder);
        }
    }
}

// To keep your world spinning you need to call progress function. 
// I was about to pass Apollo delta-time to it, but changed my mind and passed float64 seconds. Prove me wrong (for real, if you have better idea i want to hear it).
// The condition is enum_flag value that represent current game condition. I wanted it exposed, so user can define cool custom game stages. As you can see it only accepts enum_flags

progress :: inline (world: *World, delta_time: Delta_Time, condition: $CT = 0) #modify {
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

    WT :: type_of(world);
    
    procs :: Entity_Procs.{
        new_entity = (components: ..Any) -> Entity {
            return new_entity(cast(WT)context.world_ptr, components);
        },
        set = (entity: Entity, components: ..Any) {
            set(cast(WT)context.world_ptr, entity, components);
        },
        erase = (entity: Entity, types: ..Type) {
            erase(cast(WT)context.world_ptr, entity, types);
        },
        destroy = (entity: Entity) {
            destroy(cast(WT)context.world_ptr, entity);
        },
        dump = (entity: Entity) {
            dump(cast(WT)context.world_ptr, entity);
        },
    };
    
    WT._progress_impl(world, xx delta_time, xx condition,, ent_procs = procs, world_ptr = world, jay_delta_time = delta_time);
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

    print_to_builder(*builder, "World_%:\n", cast(s64)*world);

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