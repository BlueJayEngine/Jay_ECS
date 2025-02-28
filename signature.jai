Signature :: struct (reg: [$SIZE]Type) {
    #as base: [(SIZE + 63) >> 6]s64;
}

match :: (a: $ST/Signature, b: ST) -> bool {
    return #insert -> string {
        comparsions: [..]string;
        for index: 0..ST.base.count-1 {
            array_add(*comparsions, sprint("a.base[%] & b.base[%] == b.base[%]", index, index, index));
        }
        return join(join(..comparsions, " && "), ";");
    };
}

equal :: inline (a: *$ST/Signature, b: *ST) -> bool {
    return !memcmp(a, b, size_of(ST));
}

walk_components :: (in_signature: $ST/Signature, code: Code) #expand {
    for p_index: 0..ST.base.count-1 {
        part := in_signature.base[p_index];
        `c_index: s64 = ---;
        while true {
            c_index = bit_scan_forward(part) - 1;
            if c_index >= 0 {
                part &= ~(1<<(c_index));
                `comp_type := ST.reg[c_index];
                `comp_info := cast(*Type_Info)comp_type;
                #insert code;
            } else break;
        }
    }
}

sign :: ($reg: [$N]Type, components: []Type) -> Signature(reg) {
    result: Signature(reg);

    for component: components {
        exists, index := array_find(reg, component);

        if exists {
            result.base[index >> 6] |= (1 << (index & 63));   
        } else {
            log_error("Type % is never used. Terminated", component);
        }
    }

    return result;
}

sign_from_any :: (world: World, components: []Any) -> Signature(world.component_registry), [world.component_registry.count]*void {
    result: Signature(world.component_registry);
    values: [world.component_registry.count]*void;

    for component: components {
        type: Type;
        value: *void = null;
        
        if !component.type {
            log_error("Type is %. That's should never be happening", component.type);
        }
        
        if component.type.type == .TYPE {
            type = (cast(*Type)component.value_pointer).*;
        } else {
            type = (cast(*Type)*component.type).*;
            value = component.value_pointer;
        }

        exists, c_index := array_find(world.component_registry, type);
        if exists {
            result.base[c_index >> 6] |= (1 << (c_index & 63)); 
            values[c_index] = value;
        } else {
            log_error("Type % is never used. Terminated", type);
        }
    }

    return result, values;
}

sign_and :: (a: Signature($REG), b: Signature(REG)) -> Signature(REG) {
    result: Signature(REG);
    #insert -> string {
        comparsions: [..]string;
        for index: 0..result.base.count-1 {
            array_add(*comparsions, sprint("result.base[%] = a.base[%] & b.base[%];", index, index, index));
        }
        return join(..comparsions, "\n\t");
    };

    return result;
}

sign_or :: (a: Signature($REG), b: Signature(REG)) -> Signature(REG) {
    result: Signature(REG);
    #insert -> string {
        comparsions: [..]string;
        for index: 0..result.base.count-1 {
            array_add(*comparsions, sprint("result.base[%] = a.base[%] | b.base[%];", index, index, index));
        }
        return join(..comparsions, "\n\t");
    };

    return result;
}

sign_not :: (a: Signature($REG), b: Signature(REG)) -> Signature(REG) {
    result: Signature(REG) = a;
    #insert -> string {
        comparsions: [..]string;
        for index: 0..result.base.count-1 {
            array_add(*comparsions, sprint("result.base[%] &= ~b.base[%];", index, index, index));
        }
        return join(..comparsions, "\n\t");
    };

    return result;
}

count_components :: inline (sign: Signature($REG)) -> s32 {
    return #insert -> string { 
        counts := NewArray(Signature(REG).base.count, string);
        for 0..sign.base.count-1 {
            counts[it] = tprint("popcount(sign.base[%])", it);
        }
        return join(join(..counts, " + "), ";");
    };
}