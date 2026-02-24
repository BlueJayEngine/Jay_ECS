#import "Basic";
#import "String";
#import "File";
#import "File_Utilities";
#import "Compiler";
#import "Process";
#import "Metaprogram_Plugins";

#run {
    set_build_options_dc(.{ do_output = false });

    main_workspace := compiler_create_workspace(path_filename(trim(#filepath, "/")));

    build_options := get_build_options();

    new_path: [..]string;
    array_add(*new_path, ..build_options.import_path);
    array_add(*new_path, "../..");
    build_options.import_path = new_path;

    #if #exists(JAILS_DIAGNOSTICS_BUILD) build_options.output_type = .NO_OUTPUT;

    build_options.backend = .X64;
    set_optimization(*build_options, .DEBUG);
    build_options.array_bounds_check = .ON;

    args := build_options.compile_time_command_line;
    success: bool;

    plugins_to_create: [..] Plugin_To_Create;

    // For custom metaprograms, plugin arguments (+PluginName) are not in compile_time_command_line.
    // We need to use get_toplevel_command_line() and skip the first 2 args (compiler name and build script).
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



    // Process build script arguments
    for arg: args {
        if arg == "release" || arg == "-release" {
            build_options.backend = .LLVM;
            set_optimization(*build_options, Optimization_Type.OPTIMIZED_VERY_SMALL, false);
        }
        else if arg == "debug" || arg == "-release_debug" {
            // LLVM backend with maximum optimization but keeping debug symbols
            build_options.backend = .LLVM;
            build_options.llvm_options.disable_inlining = true;
            set_optimization(*build_options, Optimization_Type.OPTIMIZED_VERY_SMALL, true);
        }
        else if arg == "-" {
            // Separator between plugin args and build args - skip
            continue;
        }
        else {
            log("Unknown build argument: '%'", arg);
        }
    }

    build_options.output_type = .EXECUTABLE;
    build_options.output_executable_name = path_filename(trim(#filepath, "/"));
    make_directory_if_it_does_not_exist(build_options.output_path);

    plugins: [..]*Metaprogram_Plugin;
    success = init_plugins(plugins_to_create, *plugins, main_workspace);
    if !success {
        log_error("A plugin init() failed. Exiting.\n");
        exit(1);
    }

    set_build_options(build_options, main_workspace);

    intercept_flags: Intercept_Flags;
    for plugins if it.before_intercept it.before_intercept(it, *intercept_flags);

    compiler_begin_intercept(main_workspace, intercept_flags);

    for plugins if it.add_source it.add_source(it);
    add_build_file("main.jai", main_workspace);

    message_loop(plugins);

    compiler_end_intercept(main_workspace);

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
