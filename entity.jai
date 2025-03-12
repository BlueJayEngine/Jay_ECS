Entity :: s64;

ENTITY_NULL :: 0xffffffff;

Entity_Info :: struct {
    index: u32;
    generation: u32;
    #place index;
    wrapped: Entity;
}

#assert(size_of(Entity) == size_of(Entity_Info));

Entity_State :: struct (reg: [$SIZE] Type) {
    using info: Entity_Info;

    arch: *Archetype(reg);
    arch_index: s64;
}

Entity_Procs :: struct {
    new_entity: (components: ..Any) -> Entity;
    set: (entity: Entity, components: ..Any);
    erase: (entity: Entity, targets: ..Type);
    destroy: (entity: Entity);
    dump: (entity: Entity);
}


#add_context ent_procs := _default_ent_procs;
_default_ent_procs :: Entity_Procs.{
    new_entity = (components: ..Any) -> Entity {
        log_error("Usage of entity procedures with no world argument is forbidden outside of system. Use 'new_entity :: (world: World, components: ..Any) -> Entity' instead");
        return ENTITY_NULL;
    },
    set = (entity: Entity, components: ..Any) {
        log_error("Usage of entity procedures with no world argument is forbidden outside of system. Use 'set :: (world: World, entity: Entity, components: ..Any)' instead");
    },
    erase = (entity: Entity, types: ..Type) {
        log_error("Usage of entity procedures with no world argument is forbidden outside of system. Use 'erase :: (world: World, entity: Entity, targets: ..Type)' instead");
    },
    destroy = (entity: Entity) {
        log_error("Usage of entity procedures with no world argument is forbidden outside of system. Use 'destroy :: (world: World, entity: Entity)' instead");
    },
    dump = (entity: Entity) {
        log_error("Usage of entity procedures with no world argument is forbidden outside of system. Use 'dump :: (world: World, entity: Entity)' instead");
    },
};


wrap :: inline (e_info: Entity_Info) -> Entity {
    return e_info.wrapped;
}

unwrap :: inline (entity: Entity) -> Entity_Info {
    return .{wrapped=entity};
}

is_valid :: (world: World, entity: Entity) -> bool {
    e_info := unwrap(entity);
    return e_info.generation == world.entities[e_info.index].generation;
}

new_entity :: inline (components: ..Any) -> Entity {
    return context.ent_procs.new_entity(..components);
};

set :: inline (entity: Entity, components: ..Any) {
    context.ent_procs.set(entity, ..components);
};

erase :: inline (entity: Entity, targets: ..Type) {
    context.ent_procs.erase(entity, ..targets);
};

destroy :: inline (entity: Entity) {
    context.ent_procs.destroy(entity);
};

dump :: inline (entity: Entity) {
    context.ent_procs.dump(entity);
};

new_entity :: inline (world: World, components: []Any) -> Entity {
    
    e_index: s64;

    if world.thumbstones.count {
        e_index = pop(*world.thumbstones);
    } else {
        e_index = world.entities.count;
        array_add(*world.entities, Entity_State(world.component_registry).{index=xx e_index});
    }

    entity_info := *world.entities[e_index];
    entity := wrap(Entity_Info.{xx e_index, entity_info.generation});

    target_signature, values := sign_from_any(world, components);

    arch: *Archetype(world.component_registry) = find_archetype(world, target_signature);

    make_instance(arch, entity_info, values);  

    return entity;
}

set :: inline (world: World, entity: Entity, components: []Any) {

    e_info := unwrap(entity);
    e_state := *world.entities[e_info.index];

    from_arch := e_state.arch;

    comp_mask, values := sign_from_any(world, components);

    target_signature := sign_or(comp_mask, from_arch.signature);
    
    if equal(*target_signature, *from_arch.signature) {
        instance_set(from_arch, e_state.arch_index, comp_mask, values);
        return;
    }

    to_arch := find_archetype(world, target_signature);
    old_values := instance_get(from_arch, e_state.arch_index);
    old_state := e_state.*;
    make_instance(to_arch, e_state, old_values);
    instance_set(to_arch, e_state.arch_index, comp_mask, values);
    instance_begin_destroy(from_arch, old_state.arch_index);
}

erase :: inline (world: World, entity: Entity, targets: []Type) { //TODO: change name, erase is not so suitable for component removal
    mask := sign(world.component_registry, targets);

    e_info := unwrap(entity);
    e_state := *world.entities[e_info.index];

    from_arch := e_state.arch;

    target_signature := sign_not(from_arch.signature, mask);

    if equal(*target_signature, *from_arch.signature) return;

    array_add_if_unique(*world.dirty_archs, from_arch);

    to_arch := find_archetype(world, target_signature);

    old_values := instance_get(from_arch, e_state.arch_index);
    old_state := e_state.*;

    make_instance(to_arch, e_state, old_values);
    instance_begin_destroy(from_arch, old_state.arch_index);
}

destroy :: inline (world: World, entity: Entity) {
    e_info := unwrap(entity);
    e_state := *world.entities[e_info.index];

    array_add(*world.thumbstones, e_info.index);

    instance_begin_destroy(e_state.arch, e_state.arch_index);
    
    e_state.arch = null;
    e_state.arch_index = -1;
    e_state.generation += 1;
}

dump :: inline (world: World, entity: Entity) {

    e_info := unwrap(entity);
    e_state := *world.entities[e_info.index];

    if !is_valid(world, entity) {
        log("%", tprint("Entity_% (info: %, state: INVALID): []\n", entity, e_info));
        return;
    }

    log("%", tprint("Entity_% (info: %, state: %): %\n", entity, e_info, FormatStruct.{formatter =.{e_state.*}, draw_type_name=false, use_long_form_if_more_than_this_many_members = 0}, instance_get_any(e_state.arch, e_state.arch_index)));
}