#import "Basic";

#load "../module.jai";

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
};

Component4 :: struct {
    valc1: String_Builder;
    valc2: Entity;
};

Test_Stages: enum_flags u64 {
    Q_ITER;
    Q_EACH;
    Q_RANDOM;
    DEFAULT;
    MAX;
}

main :: () {
    world: World(systems=.[
        System(test_iter, xx Test_Stages.Q_ITER),
        System(test_each, xx Test_Stages.Q_EACH),
        System(test_random, xx Test_Stages.Q_RANDOM),
        System(test_default, xx Test_Stages.DEFAULT),
        System(additional, xx Test_Stages.MAX)
    ]);

    for 0..999999 {
        components: [..]Any;
        defer array_free(components);

        array_add(*components, Component1.{xx it, "HELLO"});
        array_add(*components, Component2.{xx 999999-it, current_time_consensus()});
        array_add(*components, Component3.{});
        array_add(*components, Component4.{.{}, xx it});

        n := it % 10;

        if n > 2 {
            if n <= 6 {
                array_add(*components, Destruction1);
            }

            if n >= 4 {
                array_add(*components, Destruction2);
            }
        } 

        new_entity(*world, components);
    }
    log("-----------");
    for 0..10 {
        {
            start := current_time_consensus();
            progress(*world, 0.1, Test_Stages.DEFAULT);
            log("DEFAULT: %", to_milliseconds(current_time_consensus() - start));
        }

        {
            start := current_time_consensus();
            progress(*world, 0.1, Test_Stages.Q_ITER);
            log("ITER:    %", to_milliseconds(current_time_consensus() - start));
        }

        {
            start := current_time_consensus();
            progress(*world, 0.1, Test_Stages.Q_EACH);
            log("EACH:    %", to_milliseconds(current_time_consensus() - start));
        }

        {
            start := current_time_consensus();
            progress(*world, 0.1, Test_Stages.Q_RANDOM);
            log("RANDOM:  %", to_milliseconds(current_time_consensus() - start));
        }


        log("-----------");
    }
    free(world);
    report_memory_leaks(.{});
}

test_default :: inline (c1: *Component1, c2: *Component2, c3: *Component3, c4: *Component4) {
    c1.val1 += 1;
    c2.vala1 += 1;
    c3.valb1 += 1;
    c4.valc2 += 1;
}

test_iter :: inline (query: Query(Component1, Component2, Component3, Component4)) {
    iter1 := get_iter(query, Component1);
    iter2 := get_iter(query, Component2);
    iter3 := get_iter(query, Component3);
    iter4 := get_iter(query, Component4);

    for *c1, index: iter1 {
        c1.val1 +=  1;
    }

    for *c2, index: iter2 {
        c2.vala1 += 1;
    }

    for *c3, index: iter3 {
        c3.valb1 += 1;
    }

    for *c4, index: iter4 {
        c4.valc2 += 1;
    }
}

test_each :: (query: Query(Component1, Component2, Component3, Component4)) {
    for query {
        c1, c2, c3, c4 := components();
        c1.val1 +=  1;
        c2.vala1 += 1;
        c3.valb1 += 1;
        c4.valc2 += 1;
    }
}

test_random :: (query: Query(Component1, Component2, Component3, Component4)) {
    iter1 := get_iter(query, Component1);
    iter2 := get_iter(query, Component2);
    iter3 := get_iter(query, Component3);
    iter4 := get_iter(query, Component4);

    for index: 0..query.count-1 {
        iter1[index].val1 +=  1;
        iter2[index].vala1 += 1;
        iter3[index].valb1 += 1;
        iter4[index].valc2 += 1;
    }
}


Destruction1 :: struct { v: s32; };
Destruction2 :: struct { v: s64; };

additional :: (d1: Destruction1, d2: Destruction2) {

}