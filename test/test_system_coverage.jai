#import "Basic"()(MEMORY_DEBUGGER = true);
#import "Jay_ECS"(DEBUG = true);
#import "Hash_Table";

// ---------------------------------------------------------------------------
//  Test components
//
//  Every testable component carries a `hits` counter.  Systems increment it.
//  After progress() we assert the counter equals the expected number of ticks.
// ---------------------------------------------------------------------------

CompA :: struct { hits: s64; }
CompB :: struct { hits: s64; }
CompC :: struct { hits: s64; }  // extra component — creates superset archetypes
Tag1  :: struct { v: s8;    }  // tag-only, never queried by the main systems
Tag2  :: struct { v: s8;    }  // second tag for another archetype split

// ---------------------------------------------------------------------------
//  1. Per-entity system  (Entity, *CompA, *CompB)
//     Must visit every entity whose archetype contains {CompA, CompB}.
// ---------------------------------------------------------------------------

sys_per_entity :: inline (entity: Entity, a: *CompA, b: *CompB) {
    a.hits += 1;
    b.hits += 1;
}

// ---------------------------------------------------------------------------
//  2. Query for-each system  Query(CompA, CompB)
//     Iterates all matching entities via `for query`.
// ---------------------------------------------------------------------------

sys_query_each :: inline (query: Query(CompA, CompB)) {
    for query {
        a, b := components();
        a.hits += 1;
        b.hits += 1;
    }
} @after:sys_per_entity

// ---------------------------------------------------------------------------
//  3. Query iterator system  get_iter(query, CompA) / get_iter(query, CompB)
//     Iterates each component stream independently.
// ---------------------------------------------------------------------------

sys_query_iter :: inline (query: Query(CompA, CompB)) {
    iter_a := get_iter(query, CompA);
    iter_b := get_iter(query, CompB);

    for * it: iter_a  it.hits += 1;
    for * it: iter_b  it.hits += 1;
} @after:sys_query_each

// ---------------------------------------------------------------------------
//  4. Batched system  ([]Entity, []CompA, []CompB)
//     Receives slices — must cover every entity in every matching archetype.
// ---------------------------------------------------------------------------

sys_batched :: inline (e: []Entity, a: []CompA, b: []CompB) {
    for 0..e.count-1 {
        a[it].hits += 1;
        b[it].hits += 1;
    }
} @batch_size:4 @after:sys_query_iter

// ---------------------------------------------------------------------------
//  5. Narrow system  (Entity, *CompC)
//     Only touches entities that have CompC — proves superset matching AND
//     that entities without CompC are excluded.
// ---------------------------------------------------------------------------

sys_narrow :: inline (entity: Entity, c: *CompC) {
    c.hits += 1;
} @after:sys_batched

// ---------------------------------------------------------------------------
//  6. Without-filter system  (Entity, *CompA, *CompB) @without:CompC
//     Requires {A,B} but EXCLUDES any archetype that contains CompC.
//     Should touch Groups 1,3 but NOT Groups 2,4.
// ---------------------------------------------------------------------------

sys_without_c :: inline (entity: Entity, a: *CompA, b: *CompB) {
    a.hits += 1;
    b.hits += 1;
} @after:sys_narrow @without:CompC

// ---------------------------------------------------------------------------
//  Helpers
// ---------------------------------------------------------------------------

TICKS :: 1;   // number of progress() calls per sub-test

log_section :: (title: string) {
    log("\n========================================");
    log("  %", title);
    log("========================================\n");
}

fail :: (fmt: string, args: ..Any) {
    log_error(fmt, ..args);
    assert(false, fmt, ..args);
}

// Typed get outside of a system — reads component from archetype storage directly
world_get :: (world: World, entity: Entity, $component: Type) -> *component {
    e_state := *world.entities[entity.index];
    ptr := instance_get(e_state.arch, e_state.arch_index, component);
    return cast(*component)ptr;
}

// ---------------------------------------------------------------------------
//  Main
// ---------------------------------------------------------------------------

main :: () {

    log_section("Jay_ECS  System Coverage Tests");

    // ------------------------------------------------------------------
    //  Build the world with all five systems
    // ------------------------------------------------------------------

    world: World(.[
        sys_per_entity,
        sys_query_each,
        sys_query_iter,
        sys_batched,
        sys_narrow,
        sys_without_c,
    ]);

    // ------------------------------------------------------------------
    //  Spawn entities in several archetype configurations
    //
    //  Group 1:  {CompA, CompB}            — 10 entities
    //  Group 2:  {CompA, CompB, CompC}     — 10 entities  (superset of AB)
    //  Group 3:  {CompA, CompB, Tag1}      — 10 entities  (superset of AB, different arch)
    //  Group 4:  {CompA, CompB, CompC, Tag2} — 10 entities (superset of AB and C)
    //  Group 5:  {CompA, Tag1}             —  5 entities  (NO CompB — must NOT be touched by AB systems)
    //  Group 6:  {Tag1}                    —  5 entities  (NO CompA, NO CompB — untouched)
    // ------------------------------------------------------------------

    GROUP1 :: 10;
    GROUP2 :: 10;
    GROUP3 :: 10;
    GROUP4 :: 10;
    GROUP5 ::  5;
    GROUP6 ::  5;

    TOTAL_AB      :: GROUP1 + GROUP2 + GROUP3 + GROUP4;  // entities with {A,B}
    TOTAL_AB_NO_C :: GROUP1 + GROUP3;                    // entities with {A,B} but NOT CompC
    TOTAL_C       :: GROUP2 + GROUP4;                    // entities with CompC

    // We store entity handles so we can read back component values after progress().
    g1_entities: [GROUP1]Entity;
    g2_entities: [GROUP2]Entity;
    g3_entities: [GROUP3]Entity;
    g4_entities: [GROUP4]Entity;
    g5_entities: [GROUP5]Entity;
    g6_entities: [GROUP6]Entity;

    // Group 1: {A, B}
    for i: 0..GROUP1-1 {
        g1_entities[i] = new_entity(world, .[CompA.{}, CompB.{}]);
    }

    // Group 2: {A, B, C}
    for i: 0..GROUP2-1 {
        g2_entities[i] = new_entity(world, .[CompA.{}, CompB.{}, CompC.{}]);
    }

    // Group 3: {A, B, Tag1}
    for i: 0..GROUP3-1 {
        g3_entities[i] = new_entity(world, .[CompA.{}, CompB.{}, Tag1.{}]);
    }

    // Group 4: {A, B, C, Tag2}
    for i: 0..GROUP4-1 {
        g4_entities[i] = new_entity(world, .[CompA.{}, CompB.{}, CompC.{}, Tag2.{}]);
    }

    // Group 5: {A, Tag1}  — missing CompB
    for i: 0..GROUP5-1 {
        g5_entities[i] = new_entity(world, .[CompA.{}, Tag1.{}]);
    }

    // Group 6: {Tag1}  — missing both A and B
    for i: 0..GROUP6-1 {
        g6_entities[i] = new_entity(world, .[Tag1.{}]);
    }

    // ------------------------------------------------------------------
    //  Run systems
    // ------------------------------------------------------------------

    for 0..TICKS-1 {
        progress(*world, 0.016);
    }

    // ------------------------------------------------------------------
    //  How many times should each component be hit per tick?
    //
    //  Systems that match {A,B} (all AB entities):
    //      sys_per_entity   -> +1 to A.hits, +1 to B.hits
    //      sys_query_each   -> +1 to A.hits, +1 to B.hits
    //      sys_query_iter   -> +1 to A.hits, +1 to B.hits
    //      sys_batched      -> +1 to A.hits, +1 to B.hits
    //                          ----
    //                          4 hits per tick on A and B
    //
    //  Systems that match {A,B} @without:CompC (AB entities WITHOUT C):
    //      sys_without_c    -> +1 to A.hits, +1 to B.hits
    //                          ----
    //                          +1 extra hit for Groups 1,3 only
    //
    //  Systems that match {C}:
    //      sys_narrow       -> +1 to C.hits
    //                          ----
    //                          1 hit per tick on C
    // ------------------------------------------------------------------

    EXPECTED_AB_HITS       :: 4 * TICKS;  // Groups 2,4 (have CompC — excluded by sys_without_c)
    EXPECTED_AB_NO_C_HITS  :: 5 * TICKS;  // Groups 1,3 (no CompC — also hit by sys_without_c)
    EXPECTED_C_HITS        :: 1 * TICKS;

    errors := 0;
    entities_checked := 0;

    // --- Group 1: {A, B} — AB hits + without_c hit ---
    log_section(tprint("Group 1: {CompA, CompB}  x%  — expect % hits on A,B (incl @without:CompC)", GROUP1, EXPECTED_AB_NO_C_HITS));
    for i: 0..GROUP1-1 {
        a := world_get(world, g1_entities[i], CompA);
        b := world_get(world, g1_entities[i], CompB);
        if a.hits != EXPECTED_AB_NO_C_HITS { fail("  FAIL  G1[%] CompA.hits = %  expected %", i, a.hits, EXPECTED_AB_NO_C_HITS); errors += 1; }
        if b.hits != EXPECTED_AB_NO_C_HITS { fail("  FAIL  G1[%] CompB.hits = %  expected %", i, b.hits, EXPECTED_AB_NO_C_HITS); errors += 1; }
        entities_checked += 1;
    }
    log("  PASS  Group 1: all % entities correct", GROUP1);

    // --- Group 2: {A, B, C} — AB hits + C hits ---
    log_section(tprint("Group 2: {CompA, CompB, CompC}  x%  — expect % AB, % C", GROUP2, EXPECTED_AB_HITS, EXPECTED_C_HITS));
    for i: 0..GROUP2-1 {
        a := world_get(world, g2_entities[i], CompA);
        b := world_get(world, g2_entities[i], CompB);
        c := world_get(world, g2_entities[i], CompC);
        if a.hits != EXPECTED_AB_HITS { fail("  FAIL  G2[%] CompA.hits = %  expected %", i, a.hits, EXPECTED_AB_HITS); errors += 1; }
        if b.hits != EXPECTED_AB_HITS { fail("  FAIL  G2[%] CompB.hits = %  expected %", i, b.hits, EXPECTED_AB_HITS); errors += 1; }
        if c.hits != EXPECTED_C_HITS  { fail("  FAIL  G2[%] CompC.hits = %  expected %", i, c.hits, EXPECTED_C_HITS);  errors += 1; }
        entities_checked += 1;
    }
    log("  PASS  Group 2: all % entities correct", GROUP2);

    // --- Group 3: {A, B, Tag1} — AB hits + without_c hit, no C ---
    log_section(tprint("Group 3: {CompA, CompB, Tag1}  x%  — expect % AB (incl @without:CompC)", GROUP3, EXPECTED_AB_NO_C_HITS));
    for i: 0..GROUP3-1 {
        a := world_get(world, g3_entities[i], CompA);
        b := world_get(world, g3_entities[i], CompB);
        if a.hits != EXPECTED_AB_NO_C_HITS { fail("  FAIL  G3[%] CompA.hits = %  expected %", i, a.hits, EXPECTED_AB_NO_C_HITS); errors += 1; }
        if b.hits != EXPECTED_AB_NO_C_HITS { fail("  FAIL  G3[%] CompB.hits = %  expected %", i, b.hits, EXPECTED_AB_NO_C_HITS); errors += 1; }
        entities_checked += 1;
    }
    log("  PASS  Group 3: all % entities correct", GROUP3);

    // --- Group 4: {A, B, C, Tag2} — AB hits + C hits ---
    log_section(tprint("Group 4: {CompA, CompB, CompC, Tag2}  x%  — expect % AB, % C", GROUP4, EXPECTED_AB_HITS, EXPECTED_C_HITS));
    for i: 0..GROUP4-1 {
        a := world_get(world, g4_entities[i], CompA);
        b := world_get(world, g4_entities[i], CompB);
        c := world_get(world, g4_entities[i], CompC);
        if a.hits != EXPECTED_AB_HITS { fail("  FAIL  G4[%] CompA.hits = %  expected %", i, a.hits, EXPECTED_AB_HITS); errors += 1; }
        if b.hits != EXPECTED_AB_HITS { fail("  FAIL  G4[%] CompB.hits = %  expected %", i, b.hits, EXPECTED_AB_HITS); errors += 1; }
        if c.hits != EXPECTED_C_HITS  { fail("  FAIL  G4[%] CompC.hits = %  expected %", i, c.hits, EXPECTED_C_HITS);  errors += 1; }
        entities_checked += 1;
    }
    log("  PASS  Group 4: all % entities correct", GROUP4);

    // --- Group 5: {A, Tag1} — NO CompB, so AB systems must NOT touch ---
    log_section(tprint("Group 5: {CompA, Tag1}  x%  — expect 0 hits (no CompB)", GROUP5));
    for i: 0..GROUP5-1 {
        a := world_get(world, g5_entities[i], CompA);
        if a.hits != 0 { fail("  FAIL  G5[%] CompA.hits = %  expected 0 (should not be touched)", i, a.hits); errors += 1; }
        entities_checked += 1;
    }
    log("  PASS  Group 5: all % entities untouched", GROUP5);

    // --- Group 6: {Tag1} — NO CompA, NO CompB — completely untouched ---
    // (Tag1 has no hits field, so we just confirm the entity is still valid)
    log_section(tprint("Group 6: {Tag1}  x%  — expect valid, untouched", GROUP6));
    for i: 0..GROUP6-1 {
        if !is_valid(world, g6_entities[i]) { fail("  FAIL  G6[%] entity invalid!", i); errors += 1; }
        entities_checked += 1;
    }
    log("  PASS  Group 6: all % entities valid and untouched", GROUP6);

    // ------------------------------------------------------------------
    //  Aggregate counts — make sure the total entity count is right
    // ------------------------------------------------------------------

    log_section("Aggregate Counts");

    total_spawned :: GROUP1 + GROUP2 + GROUP3 + GROUP4 + GROUP5 + GROUP6;
    log("  Total entities spawned:  %", total_spawned);
    log("  Entities checked:        %", entities_checked);
    log("  Entities with AB match:  %  (expected %)", TOTAL_AB, TOTAL_AB);
    log("  Entities with C  match:  %  (expected %)", TOTAL_C, TOTAL_C);

    if entities_checked != total_spawned {
        fail("  FAIL  checked % but spawned %", entities_checked, total_spawned);
    }

    // ------------------------------------------------------------------
    //  Multi-tick accumulation test
    //  Run 4 more ticks and verify hits accumulate correctly.
    // ------------------------------------------------------------------

    EXTRA_TICKS :: 4;

    log_section(tprint("Multi-tick accumulation (% extra ticks)", EXTRA_TICKS));

    for 0..EXTRA_TICKS-1 {
        progress(*world, 0.016);
    }

    TOTAL_TICKS :: TICKS + EXTRA_TICKS;
    EXPECTED_AB_TOTAL       :: 4 * TOTAL_TICKS;
    EXPECTED_AB_NO_C_TOTAL  :: 5 * TOTAL_TICKS;
    EXPECTED_C_TOTAL        :: 1 * TOTAL_TICKS;

    // Spot-check a few entities from each group
    {
        a := world_get(world, g1_entities[0], CompA);
        if a.hits != EXPECTED_AB_NO_C_TOTAL { fail("  FAIL  G1[0] after % ticks: CompA.hits = %  expected %", TOTAL_TICKS, a.hits, EXPECTED_AB_NO_C_TOTAL); errors += 1; }
    }
    {
        a := world_get(world, g2_entities[0], CompA);
        c := world_get(world, g2_entities[0], CompC);
        if a.hits != EXPECTED_AB_TOTAL { fail("  FAIL  G2[0] after % ticks: CompA.hits = %  expected %", TOTAL_TICKS, a.hits, EXPECTED_AB_TOTAL); errors += 1; }
        if c.hits != EXPECTED_C_TOTAL  { fail("  FAIL  G2[0] after % ticks: CompC.hits = %  expected %", TOTAL_TICKS, c.hits, EXPECTED_C_TOTAL);  errors += 1; }
    }
    {
        a := world_get(world, g3_entities[GROUP3-1], CompA);
        if a.hits != EXPECTED_AB_NO_C_TOTAL { fail("  FAIL  G3[last] after % ticks: CompA.hits = %  expected %", TOTAL_TICKS, a.hits, EXPECTED_AB_NO_C_TOTAL); errors += 1; }
    }
    {
        c := world_get(world, g4_entities[GROUP4-1], CompC);
        if c.hits != EXPECTED_C_TOTAL { fail("  FAIL  G4[last] after % ticks: CompC.hits = %  expected %", TOTAL_TICKS, c.hits, EXPECTED_C_TOTAL); errors += 1; }
    }
    {
        a := world_get(world, g5_entities[0], CompA);
        if a.hits != 0 { fail("  FAIL  G5[0] after % ticks: CompA.hits = %  expected 0", TOTAL_TICKS, a.hits); errors += 1; }
    }

    log("  PASS  Multi-tick accumulation correct");

    // ------------------------------------------------------------------
    //  Summary
    // ------------------------------------------------------------------

    log_section("RESULTS");

    if errors > 0 {
        log_error("  FAILED  % error(s) detected!", errors);
        assert(false, "System coverage test failed with % errors", errors);
    } else {
        log("  ALL TESTS PASSED");
        log("    - Per-entity system:       % entities across % archetypes", TOTAL_AB, 4);
        log("    - Query for-each:          % entities across % archetypes", TOTAL_AB, 4);
        log("    - Query iterator:          % entities across % archetypes", TOTAL_AB, 4);
        log("    - Batched system:          % entities across % archetypes", TOTAL_AB, 4);
        log("    - Narrow system (C):       % entities across % archetypes", TOTAL_C, 2);
        log("    - @without:CompC system:   % entities (excluded % with CompC)", TOTAL_AB_NO_C, TOTAL_C);
        log("    - Exclusion (no B):        % entities confirmed untouched", GROUP5);
        log("    - Exclusion (no A,B):      % entities confirmed untouched", GROUP6);
        log("    - Multi-tick (% ticks):    accumulation verified", TOTAL_TICKS);
    }

    free(world);
    report_memory_leaks(.{});
}
