
# Jay ECS 🐦

![License](https://img.shields.io/badge/lang-JAI-orange.svg) ![License](https://img.shields.io/badge/license-Apache_2.0-blue.svg) ![License](https://img.shields.io/badge/badges-included-green.svg)

A humble attempt to build an ergonomic ECS for Jai (The Language™) for healthy game development. 

## Minimal example: 📦

```jai

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
```jai
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

// Passing components by value and by pointer are the same right now, but in the future this will be important
hello_tick1 :: (entity: Entity, hello: *Hello_Info) {
    log("Hello Tick: % - %", hello, delta_time());
}

end_play :: () {
    log("End Play");
}
```

- **Random access**
You can get pointer to the component of the entity by using get(Entity, Type). What you need to know: the random access is slow. ~10x slower than everything else. Use it only if you have entity-to-entity connection.
```jai
c1 := get(it, Component1);
```

### Query systems: 🔍
The ECS supports multiple query shapes so systems can pick the access pattern they need.

- **Per-entity query loop** — pull grouped components directly:
```jai
test_each :: inline (query: Query(Component1, Component2, Component3, Component4)) {
    for query {
        c1, c2, c3, c4 := components();
        c1.val1 += 1;
        c2.vala1 += 1;
        c3.valb1 += 1;
        c4.valc2.index += 1; // Component4 holds an Entity
    }
}
```

- **Iterator access** — iterate each component stream separately:
```jai
test_iter :: inline (query: Query(Component1, Component2, Component3, Component4)) {
    iter1 := get_iter(query, Component1);
    iter2 := get_iter(query, Component2);
    iter3 := get_iter(query, Component3);
    iter4 := get_iter(query, Component4);

    for *c1, index: iter1 {
        c1.val1 += 1;
    }
    for *c2, index: iter2 {
        c2.vala1 += 1;
    }
    for *c3, index: iter3 {
        c3.valb1 += 1;
    }
    for *c4, index: iter4 {
        c4.valc2.index += 1;
    }
}
```

- **Batched arrays** — process slices of components (and entities) at once:
```jai
test_bach :: inline (e: []Entity, c1: []Component1, c2: []Component2, c3: []Component3, c4: []Component4) {
    for 0..3 { // batch size defined on the system signature
        c1[it].val1 += 1;
        c2[it].vala1 += 1;
        c3[it].valb1 += 1;
        c4[it].valc2.index += 1;
    }
}
```

Systems can also take `entity: Entity` alongside components when they need the owning entity in addition to component data.


### Entity manipulation: 🔬
```jai

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

All functions above get the world from context, so if you need to call them from outside - pass the world before entity:
```jai
my_entity := new_entity(world, .[Component1.{}, Component2]);
set(world, my_entity, .[Component2.{"new_value"}]);
erase(world, my_entity, .[Component2]);
dump(world, my_entity);
destroy(world, my_entity);
```

**NOTE:** The expectation was that the `set()` function would be used to mutate entities. If you need to efficiently update the value of a component - get it via a system argument and update it in place.

### TODO: ⌛

 - Optional components support
 - Entity relationships (flecs-like)
 - Auto-Parallelization
 - Advanced system management (ordering, bundling and other) 
