Archetype :: struct (reg: [$SIZE]Type) {
    signature: Signature(reg);

    storage: [SIZE] *void;
    owners: [..]*Entity_State(reg);
    
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

find_archetype :: inline (world: $WT/World, target_signature: Signature(WT.component_registry)) -> *Archetype(WT.component_registry) {
    for *world_arch: world.archetypes {
        if equal(*world_arch.signature, *target_signature) {
            return world_arch;
        }
    }

    array_add(*world.archetypes, make_archetype(target_signature));

    return *world.archetypes[world.archetypes.count-1];
}

expand :: (arch: *$AT/Archetype) {

    walk_components(arch.signature, #code {

        if arch.storage[c_index] {
            arch.storage[c_index] = realloc(
                arch.storage[c_index], 
                comp_info.runtime_size * arch.max_count, 
                comp_info.runtime_size * arch.max_count * 2,, 
                arch.allocator);
            arch.max_count *= 2;
        } else {
            arch.storage[c_index] = alloc(comp_info.runtime_size * 4,, arch.allocator);
            arch.max_count = 4;
        }
    });
}

make_instance :: (arch: *$AT/Archetype, e_state: *$EST/World.Entity_State, values: []*void = .[]) {
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

    array_add(*arch.owners, e_state);

    e_state.arch = arch;
    e_state.arch_index = arch.count;

    arch.count += 1;
}

instance_begin_destroy :: (arch: *Archetype, index: s64) {
    array_add(*arch.to_destroy, index);
}

instance_destroy :: (arch: *$AT/Archetype, index: s64) {

    arch.owners[index], arch.owners[arch.owners.count-1] = arch.owners[arch.owners.count-1], arch.owners[index];
    arch.owners[index].arch_index = index;

    old_owner := pop(*arch.owners);

    storage: *void;
    type: *Type_Info;

    walk_components(arch.signature, #code {
        storage = arch.storage[c_index]; 
        type = cast(*Type_Info)AT.reg[c_index];

        memcpy(storage + type.runtime_size * index, storage + type.runtime_size * (arch.count-1), type.runtime_size);
    });
    arch.count -= 1;
}


instance_get_any :: (arch: *$AT/Archetype, index: s64) -> []Any {
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

instance_get :: (arch: *$AT/Archetype, index: s64) -> [AT.SIZE]*void {
    values: [AT.SIZE]*void;

    walk_components(arch.signature, #code {
        values[c_index] = arch.storage[c_index] + (comp_info.runtime_size * index);
    });
    
    return values;
}

instance_set :: (arch: *$AT/Archetype, index: s64, comp_mask: $ST/Signature, values: [AT.SIZE]*void) {
    walk_components(comp_mask, #code {
        memory : *void = arch.storage[c_index] + comp_info.runtime_size * index;
        memcpy(memory, values[c_index], comp_info.runtime_size);
    });
}


dump :: (arch: *$AT/Archetype, builder: *String_Builder) {

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