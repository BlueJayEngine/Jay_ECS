
# Jay ECS 🐦

![License](https://img.shields.io/badge/lang-JAI-orange.svg) ![License](https://img.shields.io/badge/license-Apache_2.0-blue.svg) ![License](https://img.shields.io/badge/badges-included-green.svg)

A humble attempt to build an ergonomic ECS in Jai (The Language™) for healthy game development. 

## Minimal example: 📦

```odin

#import "Jay_ECS";

#load "systems_example.jai" // begin_play(), hello_tick() and end_play() systems

Game_Stage :: enum_flags { // simple game stages example
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
        System(begin_play, xx Game_Stage.BEGIN),  // yeh, systems should be known at compile time
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

### Systems example: ⚙️
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

// Passing components by value and by pointer are same right now, but in the future this will be important
hello_tick1 :: (entity: Entity, hello: *Hello_Info) {
    log("Hello Tick: % - %", hello, delta_time());
}

end_play :: () {
    log("End Play");
}
```


### Entity manipulation: 🔬
```odin

// Create new entity:
my_entity := new_entity(Component1.{}, Component2); 

// A type cannot be a component, so-any values of type “Type” will be treated as default values of that type ( Component2 and Component2.{} are equal 🤪) 

// Add or replace component:
set(my_entity, Component2.{"new_value"});

// Remove component from entity:
erase(my_entity, Component2);

// Print entity to logs:
dump(my_entity);

// Destroy entire entity:
destroy(my_entity);

```

All functions above gets world from context, so if you need to call them from outside - pass world before entity:
```odin
my_entity := new_entity(world, Component1.{}, Component2);
set(world, my_entity, Component2.{"new_value"});
erase(world, my_entity, Component2);
dump(world, my_entity);
destroy(world, my_entity);
```

**NOTE:** The expectation was that the `set()` function would be used to mutate entities. If you need to efficiently update the value of a component - get it via a system argument and update it in place.

### TODO: ⌛

 - Queries and Options:
 ```odin
 // Options to iterate over entities that may have no component, 
 // but should pe processed somehow:
 system_with_option :: (entity: Entity, comp: Option(Component)) {
 }
 
 // Queries to iterate over other entities that have queried components:
 system_with_option :: (entity: Entity, others: Query(Component, Other_Component)) {
 }
 ```
 - Auto-Parallelization
 - Advanced system management (ordering, bundling and other) 
