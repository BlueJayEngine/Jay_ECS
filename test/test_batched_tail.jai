#import "Basic"()(MEMORY_DEBUGGER = true);
#import "Jay_ECS"(DEBUG = true);
#import "Hash_Table";

// ---------------------------------------------------------------------------
//  Components
// ---------------------------------------------------------------------------

Counter :: struct { hits: s64; }

// ---------------------------------------------------------------------------
//  Systems — batch_size:4, so entity counts that aren't multiples of 4
//  will have a tail batch with fewer elements.
// ---------------------------------------------------------------------------

sys_batch :: inline (e: []Entity, c: []Counter) {
    for 0..e.count-1 {
        c[it].hits += 1;
    }
} @batch_size:4

// ---------------------------------------------------------------------------
//  Helpers
// ---------------------------------------------------------------------------

world_get :: (world: World, entity: Entity, $component: Type) -> *component {
    e_state := *world.entities[entity.index];
    ptr := instance_get(e_state.arch, e_state.arch_index, component);
    return cast(*component)ptr;
}

fail :: (fmt: string, args: ..Any) {
    log_error(fmt, ..args);
    assert(false, fmt, ..args);
}

// ---------------------------------------------------------------------------
//  Main — test every interesting entity count around batch boundaries
// ---------------------------------------------------------------------------

main :: () {

    BATCH_SIZE :: 4;

    // Test counts: 0 through 17, covering:
    //   0          — empty, no batches
    //   1,2,3      — pure tail, smaller than one batch
    //   4          — exactly one batch, no tail
    //   5,6,7      — one full batch + tail of 1,2,3
    //   8          — exactly two batches, no tail
    //   9..11      — two full batches + tail
    //   12         — three full batches, no tail
    //   13..15     — three full batches + tail
    //   16         — four full batches, no tail
    //   17         — four full batches + tail of 1

    errors := 0;

    test_counts :: s64.[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17];

    for test_count: test_counts {
        world: World(.[sys_batch]);

        entities: [17]Entity;  // max we'll use

        for i: 0..test_count-1 {
            entities[i] = new_entity(world, .[Counter.{}]);
        }

        progress(*world, 0.016);

        // Every entity must have exactly 1 hit
        for i: 0..test_count-1 {
            c := world_get(world, entities[i], Counter);
            if c.hits != 1 {
                fail("  FAIL  count=% entity[%] hits=%  expected 1", test_count, i, c.hits);
                errors += 1;
            }
        }

        tail := test_count % BATCH_SIZE;
        full_batches := test_count / BATCH_SIZE;
        log("  PASS  count=%  (% full batches + % tail)", test_count, full_batches, tail);

        free(world);
    }

    // ------------------------------------------------------------------
    //  Multi-tick with tail — make sure tails accumulate correctly
    // ------------------------------------------------------------------

    TICK_COUNT :: 10;

    {
        world: World(.[sys_batch]);

        entities: [7]Entity;  // 7 = 1 full batch + tail of 3

        for i: 0..6 {
            entities[i] = new_entity(world, .[Counter.{}]);
        }

        for 0..TICK_COUNT-1 {
            progress(*world, 0.016);
        }

        for i: 0..6 {
            c := world_get(world, entities[i], Counter);
            if c.hits != TICK_COUNT {
                fail("  FAIL  multi-tick entity[%] hits=%  expected %", i, c.hits, TICK_COUNT);
                errors += 1;
            }
        }

        log("  PASS  multi-tick: 7 entities x % ticks, all hits == %", TICK_COUNT, TICK_COUNT);

        free(world);
    }

    // ------------------------------------------------------------------
    //  Summary
    // ------------------------------------------------------------------

    log("\n=== RESULTS ===\n");

    if errors > 0 {
        log_error("FAILED with % errors", errors);
        assert(false);
    } else {
        log("ALL BATCHED TAIL TESTS PASSED");
        log("  - Tested entity counts 0..17 (batch_size=4)");
        log("  - Verified tail batches receive correct slice lengths");
        log("  - Multi-tick accumulation verified for tail entities");
    }

    report_memory_leaks(.{});
}
