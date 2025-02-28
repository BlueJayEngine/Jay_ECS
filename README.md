
# Jay ECS 🐦

![License](https://img.shields.io/badge/lang-JAI-orange.svg) ![License](https://img.shields.io/badge/license-Apache_2.0-blue.svg) ![License](https://img.shields.io/badge/badges-included-green.svg)

A humble attempt to build an ergonomic ECS in Jai (The Language™) for healthy game development. 

## Minimal example 📦

```odin

#import "Jay_ECS";

#load "systems_example.jai" // begin_play(), hello_tick() and end_play() systems

Game_Stage :: enum_flags {
    BEGIN;
    TICK;
    END;
}

Hello_Info :: struct { // just a silly component
    some_number: s32;
    some_string: string;
}

main :: () {
    world: World(systems = .[
        System(begin_play, xx Game_Stage.BEGIN),
        System(hello_tick, xx Game_Stage.TICK),
        System(end_play, xx Game_Stage.END)
    ]);


    progress(*world, 0, Game_Stage.BEGIN);


    for 0..100 { // my cool game loop
        progress(*world, 0.5, Game_Stage.TICK); // 0.5 is a lie! Calc delta time by yourself! 
    }

    progress(*world, 0.5, Game_Stage.END);

    free(world);
}

```

Systems example:
```odin
#import "Basic";

// Systems with no arguments fires once per "progress" call.

begin_play :: () {
    log("Begin Play");
    entity1 := new_entity(Hello_Info.{xx to_seconds(current_time_consensus()), "My name is Eric"});
    entity2 := new_entity(Hello_Info.{xx to_seconds(current_time_consensus()), "My name is Jumbo"});
}

// Systems with arguments fires for each matching entity 
hello_tick :: (entity: Entity, hello: Hello_Info) {
    log("Hello Tick: % - %", hello, delta_time());
}

end_play :: () {
    log("End Play");
}
```