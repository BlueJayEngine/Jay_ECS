# Jay_ECS

`Jay_ECS` is a compile-time, archetype-based ECS for Jai.

It is designed for the Jay engine, but can be used as a standalone module in any Jai project that wants predictable data layout and low-overhead system execution.

## What it actually is

- Archetype ECS storage (`[]Entity` owners + tightly packed component arrays per archetype)
- Compile-time system analysis (system arguments define required components)
- Static world definition (`World(.[...systems...])`), no runtime system registration
- Deterministic system order with `@before:<system>` and `@after:<system>` notes
- Multiple processing styles: per-entity, query loops, and batched slices
- Built-in per-tick `delta_time()` context value inside systems

## Quick start

```jai
#import "Basic";
#import "Jay_ECS";

Position :: struct { x, y: float32; }
Velocity :: struct { x, y: float32; }

spawned: bool = false;

spawn :: () {
    if spawned return; // TODO: add system groups to avoid condition management
    
    new_entity(Position.{0, 0}, Velocity.{1, 0});
    new_entity(Position.{10, 5}, Velocity.{0, -1});

    spawned = true;
}

move :: (entity: Entity, p: *Position, v: *Velocity) {
    dt := xx delta_time();
    p.x += v.x * dt;
    p.y += v.y * dt;
} @after:spawn

main :: () {
    world: World(.[spawn, move]);

    for 0..59 {
        progress(*world, 1.0 / 60.0);
    }

    free(world);
}
```

## System argument shapes

The way you write system parameters controls how the system executes.

### 1) Run once per `progress`

```jai
begin_play :: () {
    // Called once each progress() tick
}
```

### 2) Per-entity matching

```jai
integrate :: (entity: Entity, p: *Position, v: *Velocity) {
    // Called for each entity that has Position + Velocity
}
```

### 3) Query view

```jai
tick_query :: (query: Query(Position, Velocity)) {
    for query {
        p, v := components();
        p.x += v.x;
    }
}
```

You can also use iterators:

```jai
tick_iter :: (query: Query(Position, Velocity)) {
    pos := get_iter(query, Position);
    for *p: pos {
        p.x += 1;
    }
}
```

### 4) Batched slices

```jai
tick_batch :: (e: []Entity, p: []Position, v: []Velocity) {
    for 0..e.count-1 {
        p[it].x += v[it].x;
        p[it].y += v[it].y;
    }
} @batch_size:64
```

Batch mode is useful when you want explicit chunked processing.

## System notes

- `@before:<system_name>`: run this system before another system
- `@after:<system_name>`: run this system after another system
- `@without:<ComponentName>`: include matching entities, but exclude archetypes containing that component
- `@batch_size:<N>`: set batch size for slice-based systems (default is `4`)

## Entity operations

Inside systems, world-free overloads use ECS context:

```jai
e := new_entity(Position.{}, Velocity.{});
set(e, Velocity.{2, 0});
erase(e, Velocity);
destroy(e);
```

Outside systems, use explicit world overloads:

```jai
e := new_entity(world, .[Position.{}, Velocity.{}]);
set(world, e, .[Velocity.{2, 0}]);
erase(world, e, .[Velocity]);
destroy(world, e);
```

`get(entity, ComponentType)` is available, but direct component access through system parameters is the intended fast path.

## Important constraints

- Systems are fixed at compile time when you create `World`
- Component registry is inferred from system argument types (and query component lists)
- If you use a component type that never appears in any system signature, ECS logs an error for that type
- Systems cannot mix batched (`[]Component`) and non-batched (`Component` / `*Component`) component arguments in the same signature

## Debug/testing notes

- Build with `#import "Jay_ECS"(DEBUG = true);` to enable per-system timing capture (`system_timings()`)
- See `test/` for concrete coverage of:
  - per-entity systems
  - query loops + iterators
  - batched tail handling
  - `@without` filtering
