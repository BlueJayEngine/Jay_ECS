#import "Basic"()(MEMORY_DEBUGGER = true);
#import "Jay_ECS"(DEBUG = true);
#import "Hash_Table";

// ---------------------------------------------------------------------------
//  Components
// ---------------------------------------------------------------------------

Health   :: struct { hits: s64; }
Poison   :: struct { hits: s64; }
Shield   :: struct { hits: s64; }
Armor    :: struct { hits: s64; }

// ---------------------------------------------------------------------------
//  Systems
// ---------------------------------------------------------------------------

// Touches all entities with Health — baseline, no filter
sys_all_health :: inline (entity: Entity, h: *Health) {
    h.hits += 1;
}

// Touches Health entities that do NOT have Poison
sys_healthy :: inline (entity: Entity, h: *Health) {
    h.hits += 10;
} @after:sys_all_health @without:Poison

// Touches Health entities that have neither Poison nor Shield
sys_vulnerable :: inline (entity: Entity, h: *Health) {
    h.hits += 100;
} @after:sys_healthy @without:Poison @without:Shield

// Touches Poison entities — so Poison stays in the registry
sys_tick_poison :: inline (entity: Entity, p: *Poison) {
    p.hits += 1;
} @after:sys_vulnerable

// Touches Shield entities — so Shield stays in the registry
sys_tick_shield :: inline (entity: Entity, s: *Shield) {
    s.hits += 1;
} @after:sys_tick_poison

// Touches Armor entities — so Armor stays in the registry
sys_tick_armor :: inline (entity: Entity, a: *Armor) {
    a.hits += 1;
} @after:sys_tick_shield

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
//  Main
// ---------------------------------------------------------------------------

main :: () {

    world: World(.[
        sys_all_health,
        sys_healthy,
        sys_vulnerable,
        sys_tick_poison,
        sys_tick_shield,
        sys_tick_armor,
    ]);

    // ------------------------------------------------------------------
    //  Entity groups — each archetype tests a different @without combo
    //
    //  A: {Health}                    — no exclusions apply
    //  B: {Health, Poison}            — excluded by @without:Poison
    //  C: {Health, Shield}            — excluded by @without:Shield (sys_vulnerable only)
    //  D: {Health, Poison, Shield}    — excluded by both
    //  E: {Health, Armor}             — Armor is never in any @without
    //  F: {Health, Shield, Armor}     — excluded by @without:Shield (sys_vulnerable only)
    // ------------------------------------------------------------------

    COUNT :: 8;

    a_ents: [COUNT]Entity;
    b_ents: [COUNT]Entity;
    c_ents: [COUNT]Entity;
    d_ents: [COUNT]Entity;
    e_ents: [COUNT]Entity;
    f_ents: [COUNT]Entity;

    for i: 0..COUNT-1 {
        a_ents[i] = new_entity(world, .[Health.{}]);
        b_ents[i] = new_entity(world, .[Health.{}, Poison.{}]);
        c_ents[i] = new_entity(world, .[Health.{}, Shield.{}]);
        d_ents[i] = new_entity(world, .[Health.{}, Poison.{}, Shield.{}]);
        e_ents[i] = new_entity(world, .[Health.{}, Armor.{}]);
        f_ents[i] = new_entity(world, .[Health.{}, Shield.{}, Armor.{}]);
    }

    progress(*world, 0.016);

    // ------------------------------------------------------------------
    //  Expected Health.hits after 1 tick:
    //
    //  sys_all_health  (+1)   — matches all Health entities
    //  sys_healthy     (+10)  — @without:Poison        → skips B, D
    //  sys_vulnerable  (+100) — @without:Poison,Shield  → skips B, C, D, F
    //
    //  Group A {Health}:                  1 + 10 + 100 = 111
    //  Group B {Health, Poison}:          1              =   1
    //  Group C {Health, Shield}:          1 + 10         =  11
    //  Group D {Health, Poison, Shield}:  1              =   1
    //  Group E {Health, Armor}:           1 + 10 + 100 = 111
    //  Group F {Health, Shield, Armor}:   1 + 10         =  11
    // ------------------------------------------------------------------

    errors := 0;

    check :: (world: World, ents: [COUNT]Entity, expected: s64, label: string, errors: *s64) #expand {
        for i: 0..COUNT-1 {
            h := world_get(world, ents[i], Health);
            if h.hits != expected {
                fail("  FAIL  %[%] Health.hits = %  expected %", label, i, h.hits, expected);
                errors.* += 1;
            }
        }
        log("  PASS  %: all % entities have Health.hits == %", label, COUNT, expected);
    }

    log("\n=== @without filter tests ===\n");

    check(world, a_ents, 111, "A {Health}",                 *errors);
    check(world, b_ents,   1, "B {Health, Poison}",         *errors);
    check(world, c_ents,  11, "C {Health, Shield}",         *errors);
    check(world, d_ents,   1, "D {Health, Poison, Shield}", *errors);
    check(world, e_ents, 111, "E {Health, Armor}",          *errors);
    check(world, f_ents,  11, "F {Health, Shield, Armor}",  *errors);

    // ------------------------------------------------------------------
    //  Multi-tick: run 3 more and verify linear accumulation
    // ------------------------------------------------------------------

    for 0..2 progress(*world, 0.016);

    log("\n=== After 4 total ticks ===\n");

    check(world, a_ents, 111 * 4, "A {Health}",                 *errors);
    check(world, b_ents,   1 * 4, "B {Health, Poison}",         *errors);
    check(world, c_ents,  11 * 4, "C {Health, Shield}",         *errors);
    check(world, d_ents,   1 * 4, "D {Health, Poison, Shield}", *errors);
    check(world, e_ents, 111 * 4, "E {Health, Armor}",          *errors);
    check(world, f_ents,  11 * 4, "F {Health, Shield, Armor}",  *errors);

    // ------------------------------------------------------------------
    //  Summary
    // ------------------------------------------------------------------

    log("\n=== RESULTS ===\n");

    if errors > 0 {
        log_error("FAILED with % errors", errors);
        assert(false);
    } else {
        log("ALL @without TESTS PASSED");
        log("  - Single @without:Poison       correctly excluded % entities", COUNT * 2);
        log("  - Double @without:Poison,Shield correctly excluded % entities", COUNT * 4);
        log("  - Unrelated component (Armor)   did not interfere");
        log("  - Multi-tick accumulation        verified over 4 ticks");
    }
    dump(world);
    free(world);
    report_memory_leaks(.{});
}
