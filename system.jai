// System is a poly struct that wraps procedures and also may store condition enum flag value. 
// TODO: Add run_if validation

System :: struct (proc: $PT, run_if: u64 = 0) {}

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

    call_strings: [..]string;
    cast_strings: [..]string;

    arg_types := (cast(*Type_Info_Procedure)proc_type).argument_types;

    print_to_builder(builder, "if condition & systems[%].run_if == systems[%].run_if { // Handling %\n", index, index, system_type);
    print_to_builder(builder, "    sys_proc :: systems[%].proc;\n", index);

    if arg_types.count > 0 {
        for arg: arg_types {
            arg_type := (cast(*Type)*arg).*;
            call, casting := get_arg_template(arg_type, component_registry);
            array_add(*call_strings, call);
            array_add(*cast_strings, casting);
        }
        print_to_builder(builder, "    sign :: #run sign_system(component_registry, systems[%].PT);\n", index);
        print_to_builder(builder, "    for arch: world.archetypes {\n");
        print_to_builder(builder, "        if match(arch.signature, sign) {\n");
        print_to_builder(builder, "%\n", join(..cast_strings, ""));
        print_to_builder(builder, "            for owner, inst_index: arch.owners {\n");

        print_to_builder(builder, "                sys_proc(%);\n", join(..call_strings, ", "));

        print_to_builder(builder, "            }\n");
        print_to_builder(builder, "        }\n");
        print_to_builder(builder, "        cleanup(world);\n");
        print_to_builder(builder, "    }\n");
    } else {
        print_to_builder(builder, "    sys_proc();\n");
    }


    print_to_builder(builder, "}\n");
}

// TODO: system arguments rework to support scalars and harmonize passing by pointer and by value

collect_arg_types :: (proc_type: *Type_Info, result: *[..]Type, caller := #caller_location) {
    for arg: (cast(*Type_Info_Procedure)proc_type).argument_types {
        if arg.type == {
            case .POINTER; {
                ptr_type := (cast(*Type_Info_Pointer)arg).pointer_to;
                array_add_if_unique(result, (cast(*Type)*ptr_type).*);
            }

            case .VARIANT; #through;
            case .ENUM; #through;
            case .STRUCT; {
                array_add_if_unique(result, (cast(*Type)*arg).*);
            }

            case .INTEGER; {
                continue;
            }

            case; {
                log_error("Unknown system type: %", (cast(*Type)*arg).*);
            }
        }
    }
}

// Generate system signature
sign_system :: ($reg: [$SIZE]Type, $system: Type) -> Signature(reg) {

    proc_types :: #run -> []Type {
        res: [..]Type;
        collect_arg_types(cast(*Type_Info)system, *res);

        return res;
    };

    return sign(reg, proc_types);
}

get_arg_template :: (arg_type: Type, reg: []Type) -> string, string {

    if arg_type == {
        case Entity; {
            return tprint("owner.wrapped"), "";
        }

        case Delta_Time; {
            return tprint("delta_time"), "";
        }
    }

    arg_type_info := cast(*Type_Info)arg_type;

    if arg_type_info.type == .POINTER {
        ptr_target := (cast(*Type)*(cast(*Type_Info_Pointer)arg_type_info).pointer_to).*;
        registred, arg_index := array_find(reg, ptr_target);
        if !registred log_error("% is not registred!", ptr_target);
        return tprint("*arg_%[inst_index]", arg_index), tprint("            arg_% := cast(*component_registry[%])arch.storage[%];\n", arg_index, arg_index, arg_index);
    }

    registred, arg_index := array_find(reg, arg_type);
    if !registred log_error("% is not registred!", arg_type);
    return tprint("arg_%[inst_index]", arg_index), tprint("            arg_% := cast(*component_registry[%])arch.storage[%];\n", arg_index, arg_index, arg_index);
}