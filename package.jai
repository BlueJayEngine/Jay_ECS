Jay_ECS :: struct(systems: ..Type) {

    #import "Jay_Core";

    #insert #run sprint("#add_context jay_world_%: [..]World(systems);", cast(u64)systems);
    
    before_begin :: (engine: *Engine) {
        worlds := get_worlds();
        world := array_add(worlds);

        progress(world, engine.timer.delta_time, xx Game_Stage_Temp.BEFORE_BEGIN);
    }

    begin :: (engine: *Engine) {
        worlds := get_worlds();
        for *world: worlds.* {
            progress(world, engine.timer.delta_time, xx Game_Stage_Temp.BEGIN);
        }
    }

    after_begin :: (engine: *Engine) {
        worlds := get_worlds();
        for *world: worlds.* {
            progress(world, engine.timer.delta_time, xx Game_Stage_Temp.AFTER_BEGIN);
        }
    }

    before_tick :: (engine: *Engine) {
        worlds := get_worlds();
        for *world: worlds.* {
            progress(world, engine.timer.delta_time, Game_Stage_Temp.BEFORE_TICK);
        }
    }

    tick :: (engine: *Engine) {
        worlds := get_worlds();
        for *world: worlds.* {
            progress(world, engine.timer.delta_time, Game_Stage_Temp.TICK);
        }
    }

    after_tick :: (engine: *Engine) {
        worlds := get_worlds();
        for *world: worlds.* {
            progress(world, engine.timer.delta_time, Game_Stage_Temp.AFTER_TICK);
        }
    }

    before_end :: (engine: *Engine) {
        worlds := get_worlds();
        for *world: worlds.* {
            progress(world, engine.timer.delta_time, Game_Stage_Temp.BEFORE_END);
        }
    }

    end :: (engine: *Engine) {
        worlds := get_worlds();
        for *world: worlds.* {
            progress(world, engine.timer.delta_time, Game_Stage_Temp.END);
        }
    }

    after_end :: (engine: *Engine) {
        worlds := get_worlds();
        for *world: worlds.* {
            progress(world, engine.timer.delta_time, Game_Stage_Temp.AFTER_END);
            free(world);
        }
    }


    get_worlds :: inline () -> *[..]World(systems) {
        #insert #run sprint("return *context.jay_world_%;", cast(u64)systems);
    }
}

Game_Stage_Temp :: enum_flags u64 {
    BEFORE_BEGIN;
    BEGIN;
    AFTER_BEGIN;

    BEFORE_TICK;
    TICK;
    AFTER_TICK;
    
    BEFORE_END;
    END;
    AFTER_END;
}