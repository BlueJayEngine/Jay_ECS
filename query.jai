Query :: struct (components: ..Type) {  
    entities: [][]Entity;
    _offsets: []s64;

    #insert -> string {
        body_builder: String_Builder;
        
        for component, index: components {
            print_to_builder(*body_builder, "_iter_%: Iterator(components[%]);\n", index, index);
        }

        return builder_to_string(*body_builder);
    }

    count: s64;
}

// Just a view for component values 
Iterator :: struct (T: Type) {
    _values: [][]T;
    _offsets: []s64;
    count:s64;
}

init :: (world: World, query: *Query) {
    q_sign :: #run sign(world.component_registry, query.components);

    valid_archs: [..]*Archetype(world.component_registry);
    defer array_free(valid_archs);

    query.count = 0;

    for *arch: world.archetypes {
        if match(arch.signature, q_sign) {
            array_add(*valid_archs, arch);
            query.count += arch.count;
        }
    }

    query.entities = NewArray(valid_archs.count, []Entity,, temp);
    query._offsets = NewArray(valid_archs.count, s64,, temp);

    #insert -> string {
        builder: String_Builder;

        for 0..query.components.count-1 {
            print_to_builder(*builder, "query._iter_% = Iterator(query.components[%]).{_values = NewArray(valid_archs.count, []query.components[%],, temp), _offsets = query._offsets};\n", it, it, it);
        }

        return builder_to_string(*builder);
    }

    next_offset := 0;
    
    for arch, a_index: valid_archs {
        query.entities[a_index] = arch.owners;
        query._offsets[a_index] = next_offset;
        #insert -> string {
            builder: String_Builder;

            walk_components(q_sign, #code {
                success, index := array_find(query.components, comp_type);
                print_to_builder(*builder, "query._iter_%._values[a_index].data = arch.storage[%];\n", index, c_index);
                print_to_builder(*builder, "query._iter_%._values[a_index].count = arch.count;\n", index);
            });            

            return builder_to_string(*builder);
        }

        next_offset += arch.count;
    }

    #insert -> string {
        builder: String_Builder;

        for 0..query.components.count-1 {
            print_to_builder(*builder, "query._iter_%.count = next_offset;\n", it);
        }

        return builder_to_string(*builder);
    }
}

get_iter :: (query: Query, $component: Type) -> Iterator(component) {
    #insert -> string {
        builder: String_Builder;

        success, index := array_find(query.components, component);

        print_to_builder(*builder, "return query._iter_%;", index);

        return builder_to_string(*builder);
    }
}

for_expansion :: (iter: *Iterator, body: Code, flags: For_Flags) #expand {

    for arch, a_index: iter._values {
        for val, index: arch {
            #if flags & .POINTER {
                `it := *val;
            } else {
                `it := val;
            }
            `it_index := iter._offsets[a_index]+index;
            #insert (remove=#assert(false), break=break arch) body;
        }
    }
}

operator []= :: inline (iter: Iterator, index: s64, value: iter.T) {
    q_index := query_index(iter._offsets, index);
    a_index := index - iter._offsets[q_index];

    iter._values[q_index][a_index] = value;
}

operator [] :: inline (iter: Iterator, index: s64) -> *iter.T {
    q_index := query_index(iter._offsets, index);
    a_index := index - iter._offsets[q_index];
    return *iter._values[q_index][a_index];
}

for_expansion :: (query: *Query, body: Code, flags: For_Flags) #expand {
    
    #insert -> string {
        builder: String_Builder;

        print_to_builder(*builder, "`components :: inline () -> (");

        returns: [..]string;
        items: [..]string;
        

        for comp_type, index: query.components {
            array_add(*items, sprint("*query._iter_%._values[`__jay_a_index][`__jay_b_index]", index));
            array_add(*returns, sprint("*query.components[%]", index));
        }

        print_to_builder(*builder, join(..returns, separator = ", "));

        print_to_builder(*builder, ") #expand { return ");

        print_to_builder(*builder, join(..items, separator = ", "));

        print_to_builder(*builder, ";}");

        return builder_to_string(*builder);
    }
    
    for `__jay_a_index: 0..query.entities.count-1 {
        for `it, `__jay_b_index: query.entities[__jay_a_index] {
            `it_index := query._offsets[__jay_a_index]+__jay_b_index;
            #insert (remove={destroy(query.entities[__jay_a_index][__jay_b_index]);}, break=break __jay_a_index) body;
        }
    }
}

#scope_file

query_index :: (offsets: []s64, in: s64) -> s64 {

    low := 0;
    high := offsets.count;
    result := 0;

    while (low < high) {
        mid := low + (high - low) / 2;
        if (offsets[mid] <= in) {
            result = mid;
            low = mid + 1;
        } else {
            high = mid;
        }
    }

    return result;

    // result := 0;

    // for 0..offsets.count-1 {
    //     if offsets[it] > in {
    //         break;
    //     }
    //     result = it;
    // }
    // return result;
}

none :: Type.[];
