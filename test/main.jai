#import "Basic"()(MEMORY_DEBUGGER = true);
#import "Jay_ECS"(DEBUG = true);
#import "Jay_Logger";
#import "Jay_Render";
#import "Hash_Table";

Component1 :: struct {
    val1: s32;
    val2: string;
}

Component2 :: struct {
    vala1: s64;
    vala2: Apollo_Time;
}

Component3 :: struct {
    valb1: s32;
    valb2: float64 = 3.14;
}

Component4 :: struct {
    valc1: String_Builder;
    valc2: Entity;
}

Test_Stages: enum_flags u64 {
    Q_ITER;
    Q_EACH;
    Q_RANDOM;
    DEFAULT;
    BACH;
    MAX;
}

SOME_COUNT :: 999;

bubble_sort :: (array: []s64) {
    
}


main :: () {

    context.logger = jay_logger;

    world: World(.[
           test_iter,
           test_each,
           test_random, 
           test_default,
           test_bach,
           additional
    ]);

    for 0..SOME_COUNT {
        components: [..]Any;
        defer array_free(components);

        array_add(*components, Component1.{ xx it, "HELLO" });
        array_add(*components, Component2.{ xx SOME_COUNT - it, current_time_consensus() });
        array_add(*components, Component3);
        array_add(*components, Component4.{ .{}, .{index = xx it} });

        // log("new_entity: %", components);

        n := it % 10;

        if n > 2 {
            if n <= 6 {
                array_add(*components, Destruction1);
            }

            if n >= 4 {
                array_add(*components, Destruction2);
            }
        }

        new_entity(world, components);
    }

    // log("=== === === === === === === === === === === === ");
    for 0..9 {
        progress(*world, 0.1);
        timings := system_timings();
        for it, it_index : timings log("% : % μs", it_index, it);
        log("-----");
    }

    // dump(world);
    free(world);
    report_memory_leaks(.{});

    log("%", test_bach);
}

test_default :: inline (entity: Entity, c1: *Component1, c2: *Component2, c3: *Component3, c4: *Component4) {
    c1.val1 += 1;
    c2.vala1 += 1;
    c3.valb1 += 1;
    c4.valc2.index += 1;
} @before:test_each

test_each :: inline (query: Query(Component1, Component2, Component3, Component4)) {
    for query {
        c1, c2, c3, c4 := components();       
        c1.val1 += 1;
        c2.vala1 += 1;
        c3.valb1 += 1;
        c4.valc2.index += 1;
    }
}

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
} @after:test_default @without:Destruction1


test_random :: inline (query: Query(Component1, Component2, Component3, Component4)) {
    for query {
        c1 := get(it, Component1);
        c2 := get(it, Component2);
        c3 := get(it, Component3);
        c4 := get(it, Component4);

        c1.val1 += 1;
        c2.vala1 += 1;
        c3.valb1 += 1;
        c4.valc2.index += 1;
    } 
} @after:test_default @before:test_bach


test_bach :: inline (e: []Entity, c1: []Component1, c2: []Component2, c3: []Component3, c4: []Component4) {
    for 0..e.count-1 {
        // print("% ", it);
        c1[it].val1 += 1;
        c2[it].vala1 += 1;
        c3[it].valb1 += 1;
        c4[it].valc2.index += 1;
    }
} @bach_size:8 @after:test_default

Destruction1 :: struct {v: s32;}
Destruction2 :: struct {v: s64;}

additional :: (d1: Destruction1, d2: Destruction2) {
}

