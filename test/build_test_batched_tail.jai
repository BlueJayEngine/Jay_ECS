#import "Basic";
#import "Compiler";
#import "Metaprogram_Plugins";

#run {
    set_build_options_dc(.{ do_output = false });

    w := compiler_create_workspace("test_batched_tail");
    opts := get_build_options(w);

    new_path: [..]string;
    array_add(*new_path, ..opts.import_path);
    array_add(*new_path, "../..");
    opts.import_path = new_path;

    #if #exists(JAILS_DIAGNOSTICS_BUILD) opts.output_type = .NO_OUTPUT;

    opts.backend = .X64;
    set_optimization(*opts, .DEBUG);
    opts.array_bounds_check = .ON;

    args := opts.compile_time_command_line;
    success: bool;

    plugins_to_create: [..] Plugin_To_Create;

    toplevel_args := get_toplevel_command_line();
    if toplevel_args.count > 2 {
        plugin_args := array_view(toplevel_args, 2, toplevel_args.count - 2);
        success, plugins_to_create, args = parse_plugin_arguments(plugin_args);
    } else {
        success, plugins_to_create, args = parse_plugin_arguments(args);
    }

    if !success {
        log_error("Failed to parse plugin arguments.\n");
        exit(1);
    }

    for arg: args {
        if arg == "release" || arg == "-release" {
            opts.backend = .LLVM;
            set_optimization(*opts, Optimization_Type.OPTIMIZED_VERY_SMALL, false);
        }
        else if arg == "debug" || arg == "-release_debug" {
            opts.backend = .LLVM;
            opts.llvm_options.disable_inlining = true;
            set_optimization(*opts, Optimization_Type.OPTIMIZED_VERY_SMALL, true);
        }
        else if arg == "-" {
            continue;
        }
        else {
            log("Unknown build argument: '%'", arg);
        }
    }

    opts.output_type = .EXECUTABLE;
    opts.output_executable_name = "test_batched_tail";

    plugins: [..]*Metaprogram_Plugin;
    success = init_plugins(plugins_to_create, *plugins, w);
    if !success {
        log_error("A plugin init() failed. Exiting.\n");
        exit(1);
    }

    set_build_options(opts, w);

    intercept_flags: Intercept_Flags;
    for plugins if it.before_intercept it.before_intercept(it, *intercept_flags);

    compiler_begin_intercept(w, intercept_flags);

    for plugins if it.add_source it.add_source(it);
    add_build_file("test_batched_tail.jai", w);

    message_loop(plugins);

    compiler_end_intercept(w);

    for plugins if it.finish it.finish(it);
    for plugins if it.shutdown it.shutdown(it);
}

message_loop :: (plugins: []*Metaprogram_Plugin) {
    while true {
        message := compiler_wait_for_message();
        for plugins if it.message it.message(it, message);
        if message.kind == .COMPLETE break;
    }
}
