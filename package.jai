Jay_ECS :: struct($code: Code) {

    #import "Jay_Core";

    #insert #run sprint("#add_context jay_world_%: [..]World(code);", cast(u64) type_info(World(code)));

    before_begin :: (engine: *Engine) {
        worlds := get_worlds();
        array_add(worlds);
    }

    tick :: (engine: *Engine) {
        worlds := get_worlds();
        for *world: worlds.* {
            progress(world, engine.timer.delta_time);
        }
    }

    after_end :: (engine: *Engine) {
        worlds := get_worlds();
        for *world: worlds.* {
            free(world);
        }
    }

    get_worlds :: inline () -> *[..]World(code) {
        #insert #run sprint("return *context.jay_world_%;", cast(u64) type_info(World(code)));
    }
}
