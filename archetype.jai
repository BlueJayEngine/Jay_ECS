Archetype :: struct (reg: [$SIZE]Type) {
    signature: Signature(reg);

    storage: [SIZE] *void;
    owners: []Entity;
    
    count: s64;
    max_count: s64;

    to_destroy: [..]s64;

    allocator: Allocator;
}

operator == :: inline (a: Archetype($RG), b: Archetype(RG)) -> bool {
    return equal(*a.signature, *b.signature);
}

make_archetype :: (in_signature: Signature($RG)) -> Archetype(RG) {
    arch: Archetype(RG) = .{
        signature = in_signature,
        allocator = context.allocator,
    };

    expand(*arch);

    return arch;
}

find_archetype :: inline (world: World, target_signature: Signature(world.component_registry)) -> *Archetype(world.component_registry) {
    for *world_arch: world.archetypes {
        if equal(*world_arch.signature, *target_signature) {
            return world_arch;
        }
    }

    array_add(*world.archetypes, make_archetype(target_signature));

    return *world.archetypes[world.archetypes.count-1];
}

expand :: (arch: *Archetype) {

    if arch.max_count > 0 {
        walk_components(arch.signature, #code {
            arch.storage[c_index] = realloc(
                arch.storage[c_index], 
                comp_info.runtime_size * (arch.max_count + 32),
                comp_info.runtime_size * arch.max_count,, 
                arch.allocator);
        });

        arch.owners.data = realloc(
            arch.owners.data,
            size_of(Entity) * (arch.max_count + 32),
            size_of(Entity) * arch.max_count,, arch.allocator);

        arch.max_count += 32;
    } else {
        walk_components(arch.signature, #code {
            arch.storage[c_index] = alloc(comp_info.runtime_size * 32,, arch.allocator);
        });

        arch.owners.data = alloc(size_of(Entity) * 32,, arch.allocator);
        arch.max_count = 32;
    }
}

make_instance :: (arch: *Archetype, e_state: *$EST/World.Entity_State, values: []*void = .[]) {
    if arch.count>=arch.max_count {
        expand(arch);
    }

    walk_components(arch.signature, #code {

        memory : *void = arch.storage[c_index] + comp_info.runtime_size * arch.count;

        if values[c_index] {
            memcpy(memory, values[c_index], comp_info.runtime_size);
        } else {
            if comp_info.type == .STRUCT {
                tis := cast(*Type_Info_Struct) comp_info;
                if tis.initializer 
                then 
                    tis.initializer(memory);
                else
                    memset(memory, 0, comp_info.runtime_size);
            } else {
                memset(memory, 0, comp_info.runtime_size);
            }
        }
    });


    arch.owners.count += 1;
    arch.owners[arch.count] = e_state.wrapped;
    // log("%", arch.owners);

    e_state.arch = arch;
    e_state.arch_index = arch.count;

    arch.count += 1;
}

instance_begin_destroy :: (arch: *Archetype, index: s64) {
    array_add(*arch.to_destroy, index);
}

instance_destroy :: (world: World, arch: *Archetype, index: s64) {
    owner_info := *world.entities[arch.owners[index]];

    arch.owners[index], arch.owners[arch.owners.count-1] = arch.owners[arch.owners.count-1], arch.owners[index];

    owner_info.arch_index = index;

    old_owner := pop(*arch.owners);

    storage: *void;
    type: *Type_Info;

    walk_components(arch.signature, #code {
        storage = arch.storage[c_index]; 
        type = cast(*Type_Info)arch.reg[c_index];

        memcpy(storage + type.runtime_size * index, storage + type.runtime_size * (arch.count-1), type.runtime_size);
    });

    arch.count -= 1;
    log("!!! % !!!", arch.count);
}


instance_get_any :: (arch: *Archetype, index: s64) -> []Any {
    if !arch || index < 0 return .[];
    values := NewArray(count_components(arch.signature), Any,, temp);

    v_index := 0;
    
    walk_components(arch.signature, #code {

        storage := arch.storage[c_index];
        values[v_index].value_pointer = storage + (comp_info.runtime_size * index);
        values[v_index].type = comp_info;

        v_index += 1;
    });
    return values;
}

instance_get :: (arch: *Archetype, index: s64) -> [arch.SIZE]*void {
    values: [arch.SIZE]*void;

    walk_components(arch.signature, #code {
        values[c_index] = arch.storage[c_index] + (comp_info.runtime_size * index);
    });
    
    return values;
}

instance_set :: (arch: *Archetype, index: s64, comp_mask: Signature(arch.reg), values: [arch.SIZE]*void) {
    walk_components(comp_mask, #code {
        memory : *void = arch.storage[c_index] + comp_info.runtime_size * index;
        memcpy(memory, values[c_index], comp_info.runtime_size);
    });
}


dump :: (arch: *Archetype, builder: *String_Builder) {

    print_to_builder(builder, "    Arch.%:\n", arch.signature);

    for index: 0..arch.max_count-1 {
        instance := instance_get_any(arch, index);

        if index >= arch.count {
            print_to_builder(builder, "\x1b[2m");
        }

        print_to_builder(builder, "        %:\n", index);

        for component: instance {
            if component.type.type == .STRUCT {
                print_to_builder(builder, "            %,\n", FormatStruct.{formatter =.{component}, draw_type_name=true});
            } else {
                print_to_builder(builder, "            ");
                print_type_to_builder(builder, component.type);
                print_to_builder(builder, ".%,\n", component);
            }
        }
    }

    print_to_builder(builder, "\x1b[0m\n");
}

arch_free :: (arch: $AT/Archetype) {
    array_free(arch.owners);
    for arch.storage {
        free(it);
    }
    array_free(arch.to_destroy);
}