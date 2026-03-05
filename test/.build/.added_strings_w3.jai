// Workspace: test

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/matrix.jai:20.
//
//  Matrix(3,3,float32)
    _11, _12, _13: T;
    _21, _22, _23: T;
    _31, _32, _33: T;

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/matrix.jai:20.
//
//  Matrix(2,2,float32)
    _11, _12: T;
    _21, _22: T;

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/matrix.jai:20.
//
//  Matrix(4,3,float64)
    _11, _12, _13, _14: T;
    _21, _22, _23, _24: T;
    _31, _32, _33, _34: T;

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/matrix.jai:20.
//
//  Matrix(4,4,float64)
    _11, _12, _13, _14: T;
    _21, _22, _23, _24: T;
    _31, _32, _33, _34: T;
    _41, _42, _43, _44: T;

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/matrix.jai:20.
//
//  Matrix(3,3,float64)
    _11, _12, _13: T;
    _21, _22, _23: T;
    _31, _32, _33: T;

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_ECS/query.jai:5.
//
 

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/matrix.jai:20.
//
//  Matrix(2,2,float64)
    _11, _12: T;
    _21, _22: T;

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_ECS/signature.jai:134.
//
popcount(sign.base[0]);

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_ECS/query.jai:5.
//
_iter_0: Iterator(components[0]);
_iter_1: Iterator(components[1]);
_iter_2: Iterator(components[2]);
_iter_3: Iterator(components[3]);

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_ECS/world.jai:78.
//
{
    __sys_start := current_time_monotonic();
{ // Handling 3
    sys_proc :: #insert systems[3];
    sign :: #run sign_system(component_registry, type_of(sys_proc));
    for *arch: world.archetypes {
        if match(arch.signature, sign) {
            arg_0 := cast(*component_registry[0])arch.storage[0];
            arg_1 := cast(*component_registry[1])arch.storage[1];
            arg_2 := cast(*component_registry[2])arch.storage[2];
            arg_3 := cast(*component_registry[3])arch.storage[3];

            for owner, inst_index: arch.owners {
                sys_proc(owner, *arg_0[inst_index], *arg_1[inst_index], *arg_2[inst_index], *arg_3[inst_index]);
            }
        }
        cleanup(*world, arch);
    }
}
    __sys_elapsed := to_float64_seconds(current_time_monotonic() - __sys_start) * 1_000_000.0;
    table_set(*context.__jay_system_timings, "test_default", __sys_elapsed);
}
{
    __sys_start := current_time_monotonic();
{ // Handling 0
    sys_proc :: #insert systems[0];
    query_140050500416952: #run -> Type { q_index : u64 = 140050500416952; return (cast(*Type) *q_index).*; }
	init(world, *query_140050500416952);
    sys_proc(query_140050500416952);
}
    __sys_elapsed := to_float64_seconds(current_time_monotonic() - __sys_start) * 1_000_000.0;
    table_set(*context.__jay_system_timings, "test_iter", __sys_elapsed);
}
{
    __sys_start := current_time_monotonic();
{ // Handling 1
    sys_proc :: #insert systems[1];
    query_140050500416952: #run -> Type { q_index : u64 = 140050500416952; return (cast(*Type) *q_index).*; }
	init(world, *query_140050500416952);
    sys_proc(query_140050500416952);
}
    __sys_elapsed := to_float64_seconds(current_time_monotonic() - __sys_start) * 1_000_000.0;
    table_set(*context.__jay_system_timings, "test_each", __sys_elapsed);
}
{
    __sys_start := current_time_monotonic();
{ // Handling 2
    sys_proc :: #insert systems[2];
    query_140050500416952: #run -> Type { q_index : u64 = 140050500416952; return (cast(*Type) *q_index).*; }
	init(world, *query_140050500416952);
    sys_proc(query_140050500416952);
}
    __sys_elapsed := to_float64_seconds(current_time_monotonic() - __sys_start) * 1_000_000.0;
    table_set(*context.__jay_system_timings, "test_random", __sys_elapsed);
}
{
    __sys_start := current_time_monotonic();
{ // Handling 4
    sys_proc :: #insert systems[4];
    sign :: #run sign_system(component_registry, type_of(sys_proc));
    for *arch: world.archetypes {
        if match(arch.signature, sign) {
            arg_0_base := cast(*component_registry[0])arch.storage[0];
            arg_1_base := cast(*component_registry[1])arch.storage[1];
            arg_2_base := cast(*component_registry[2])arch.storage[2];
            arg_3_base := cast(*component_registry[3])arch.storage[3];

            batch_index: s64 = 0;
            batch_size: s64 = 4;
            owners: []Entity;
            while batch_index < arch.count {
                remaining := min(batch_size, arch.count - batch_index);
                owners.data = *arch.owners[batch_index];
                owners.count = remaining;
                sys_proc(owners, ([]component_registry[0]).{ data = arg_0_base + batch_index, count = remaining }, ([]component_registry[1]).{ data = arg_1_base + batch_index, count = remaining }, ([]component_registry[2]).{ data = arg_2_base + batch_index, count = remaining }, ([]component_registry[3]).{ data = arg_3_base + batch_index, count = remaining });
                batch_index += batch_size;
            }
        }
        cleanup(*world, arch);
    }
}
    __sys_elapsed := to_float64_seconds(current_time_monotonic() - __sys_start) * 1_000_000.0;
    table_set(*context.__jay_system_timings, "test_bach", __sys_elapsed);
}
{
    __sys_start := current_time_monotonic();
{ // Handling 5
    sys_proc :: #insert systems[5];
    sign :: #run sign_system(component_registry, type_of(sys_proc));
    for *arch: world.archetypes {
        if match(arch.signature, sign) {
            arg_4 := cast(*component_registry[4])arch.storage[4];
            arg_5 := cast(*component_registry[5])arch.storage[5];

            for owner, inst_index: arch.owners {
                sys_proc(arg_4[inst_index], arg_5[inst_index]);
            }
        }
        cleanup(*world, arch);
    }
}
    __sys_elapsed := to_float64_seconds(current_time_monotonic() - __sys_start) * 1_000_000.0;
    table_set(*context.__jay_system_timings, "additional", __sys_elapsed);
}

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_ECS/signature.jai:122.
//
result.base[0] &= ~b.base[0];

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_ECS/query.jai:86.
//
return query._iter_0;

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_ECS/query.jai:86.
//
return query._iter_3;

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_ECS/query.jai:86.
//
return query._iter_1;

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_ECS/query.jai:86.
//
return query._iter_2;

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_ECS/signature.jai:6.
//
a.base[0] & b.base[0] == b.base[0];

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_ECS/query.jai:126.
//
`components :: inline () -> (*query.components[0], *query.components[1], *query.components[2], *query.components[3]) #expand { return *query._iter_0._values[`__jay_a_index][`__jay_b_index], *query._iter_1._values[`__jay_a_index][`__jay_b_index], *query._iter_2._values[`__jay_a_index][`__jay_b_index], *query._iter_3._values[`__jay_a_index][`__jay_b_index];}

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_ECS/query.jai:43.
//
query._iter_0 = Iterator(query.components[0]).{_values = NewArray(valid_archs.count, []query.components[0],, temp), _offsets = query._offsets};
query._iter_1 = Iterator(query.components[1]).{_values = NewArray(valid_archs.count, []query.components[1],, temp), _offsets = query._offsets};
query._iter_2 = Iterator(query.components[2]).{_values = NewArray(valid_archs.count, []query.components[2],, temp), _offsets = query._offsets};
query._iter_3 = Iterator(query.components[3]).{_values = NewArray(valid_archs.count, []query.components[3],, temp), _offsets = query._offsets};

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_ECS/query.jai:126.
//
`components :: inline () -> (*query.components[0], *query.components[1], *query.components[2], *query.components[3]) #expand { return *query._iter_0._values[`__jay_a_index][`__jay_b_index], *query._iter_1._values[`__jay_a_index][`__jay_b_index], *query._iter_2._values[`__jay_a_index][`__jay_b_index], *query._iter_3._values[`__jay_a_index][`__jay_b_index];}

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_ECS/query.jai:58.
//
query._iter_0._values[a_index].data = arch.storage[0];
query._iter_0._values[a_index].count = arch.count;
query._iter_1._values[a_index].data = arch.storage[1];
query._iter_1._values[a_index].count = arch.count;
query._iter_2._values[a_index].data = arch.storage[2];
query._iter_2._values[a_index].count = arch.count;
query._iter_3._values[a_index].data = arch.storage[3];
query._iter_3._values[a_index].count = arch.count;

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_ECS/query.jai:74.
//
query._iter_0.count = next_offset;
query._iter_1.count = next_offset;
query._iter_2.count = next_offset;
query._iter_3.count = next_offset;

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_ECS/signature.jai:109.
//
result.base[0] = a.base[0] | b.base[0];

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/vector.jai:40.
//
    x, y, z, w: T #align 16;
    #overlay (x) values: [N] T = ---;
    #overlay (x) xy: Vector(2, T, AXES) = ---;
    #overlay (y) yz: Vector(2, T, AXES) = ---;
    #overlay (z) zw: Vector(2, T, AXES) = ---;
    #overlay (x) xyz: Vector(3, T, AXES) = ---;
    #overlay (y) yzw: Vector(3, T, AXES) = ---;

    new :: (x: T, y: T, z: T, w: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = y;
        result.values[2] = z;
        result.values[3] = w;

        return result;
    }

    new :: (x: T, y: T, zw: Vector(2, $T2, $A2)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = y;
        result.values[2] = zw.values[0];
        result.values[3] = zw.values[1];

        return result;
    }

    new :: (x: T, yz: Vector(2, $T1, $A1), w: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = yz.values[0];
        result.values[2] = yz.values[1];
        result.values[3] = w;

        return result;
    }

    new :: (x: T, yzw: Vector(3, $T1, $A1)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = yzw.values[0];
        result.values[2] = yzw.values[1];
        result.values[3] = yzw.values[2];

        return result;
    }

    new :: (xy: Vector(2, $T0, $A0), z: T, w: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = xy.values[0];
        result.values[1] = xy.values[1];
        result.values[2] = z;
        result.values[3] = w;

        return result;
    }

    new :: (xy: Vector(2, $T0, $A0), zw: Vector(2, $T1, $A1)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = xy.values[0];
        result.values[1] = xy.values[1];
        result.values[2] = zw.values[0];
        result.values[3] = zw.values[1];

        return result;
    }

    new :: (xyz: Vector(3, $T0, $A0), w: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = xyz.values[0];
        result.values[1] = xyz.values[1];
        result.values[2] = xyz.values[2];
        result.values[3] = w;

        return result;
    }

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/vector.jai:40.
//
    x, y, z: T #align 16;
    #overlay (x) values: [N] T = ---;
    #overlay (x) xy: Vector(2, T, AXES) = ---;
    #overlay (y) yz: Vector(2, T, AXES) = ---;

    new :: (x: T, y: T, z: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = y;
        result.values[2] = z;

        return result;
    }

    new :: (x: T, yz: Vector(2, $T1, $A1)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = yz.values[0];
        result.values[2] = yz.values[1];

        return result;
    }

    new :: (xy: Vector(2, $T0, $A0), z: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = xy.values[0];
        result.values[1] = xy.values[1];
        result.values[2] = z;

        return result;
    }

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/vector.jai:40.
//
    x, y: T #align 16;
    #overlay (x) values: [N] T = ---;

    new :: (x: T, y: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = y;

        return result;
    }

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/matrix.jai:20.
//
//  Matrix(4,4,float32)
    _11, _12, _13, _14: T;
    _21, _22, _23, _24: T;
    _31, _32, _33, _34: T;
    _41, _42, _43, _44: T;

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/matrix.jai:20.
//
//  Matrix(4,3,float32)
    _11, _12, _13, _14: T;
    _21, _22, _23, _24: T;
    _31, _32, _33, _34: T;

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/vector.jai:40.
//
    w, x, y, z: T #align 16;
    #overlay (w) values: [N] T = ---;
    #overlay (w) wx: Vector(2, T, AXES) = ---;
    #overlay (x) xy: Vector(2, T, AXES) = ---;
    #overlay (y) yz: Vector(2, T, AXES) = ---;
    #overlay (w) wxy: Vector(3, T, AXES) = ---;
    #overlay (x) xyz: Vector(3, T, AXES) = ---;

    new :: (w: T, x: T, y: T, z: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = w;
        result.values[1] = x;
        result.values[2] = y;
        result.values[3] = z;

        return result;
    }

    new :: (w: T, x: T, yz: Vector(2, $T2, $A2)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = w;
        result.values[1] = x;
        result.values[2] = yz.values[0];
        result.values[3] = yz.values[1];

        return result;
    }

    new :: (w: T, xy: Vector(2, $T1, $A1), z: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = w;
        result.values[1] = xy.values[0];
        result.values[2] = xy.values[1];
        result.values[3] = z;

        return result;
    }

    new :: (w: T, xyz: Vector(3, $T1, $A1)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = w;
        result.values[1] = xyz.values[0];
        result.values[2] = xyz.values[1];
        result.values[3] = xyz.values[2];

        return result;
    }

    new :: (wx: Vector(2, $T0, $A0), y: T, z: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = wx.values[0];
        result.values[1] = wx.values[1];
        result.values[2] = y;
        result.values[3] = z;

        return result;
    }

    new :: (wx: Vector(2, $T0, $A0), yz: Vector(2, $T1, $A1)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = wx.values[0];
        result.values[1] = wx.values[1];
        result.values[2] = yz.values[0];
        result.values[3] = yz.values[1];

        return result;
    }

    new :: (wxy: Vector(3, $T0, $A0), z: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = wxy.values[0];
        result.values[1] = wxy.values[1];
        result.values[2] = wxy.values[2];
        result.values[3] = z;

        return result;
    }

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/vector.jai:40.
//
    w, x, y: T #align 16;
    #overlay (w) values: [N] T = ---;
    #overlay (w) wx: Vector(2, T, AXES) = ---;
    #overlay (x) xy: Vector(2, T, AXES) = ---;

    new :: (w: T, x: T, y: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = w;
        result.values[1] = x;
        result.values[2] = y;

        return result;
    }

    new :: (w: T, xy: Vector(2, $T1, $A1)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = w;
        result.values[1] = xy.values[0];
        result.values[2] = xy.values[1];

        return result;
    }

    new :: (wx: Vector(2, $T0, $A0), y: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = wx.values[0];
        result.values[1] = wx.values[1];
        result.values[2] = y;

        return result;
    }

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/vector.jai:40.
//
    w, x: T #align 16;
    #overlay (w) values: [N] T = ---;

    new :: (w: T, x: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = w;
        result.values[1] = x;

        return result;
    }

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/vector.jai:40.
//
    roll, pitch, yaw: T #align 16;
    #overlay (roll) values: [N] T = ---;
    #overlay (roll) rollpitch: Vector(2, T, AXES) = ---;
    #overlay (pitch) pitchyaw: Vector(2, T, AXES) = ---;

    new :: (roll: T, pitch: T, yaw: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = roll;
        result.values[1] = pitch;
        result.values[2] = yaw;

        return result;
    }

    new :: (roll: T, pitchyaw: Vector(2, $T1, $A1)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = roll;
        result.values[1] = pitchyaw.values[0];
        result.values[2] = pitchyaw.values[1];

        return result;
    }

    new :: (rollpitch: Vector(2, $T0, $A0), yaw: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = rollpitch.values[0];
        result.values[1] = rollpitch.values[1];
        result.values[2] = yaw;

        return result;
    }

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/vector.jai:40.
//
    x, y: T #align 16;
    #overlay (x) values: [N] T = ---;

    new :: (x: T, y: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = y;

        return result;
    }

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/vector.jai:40.
//
    roll, pitch: T #align 16;
    #overlay (roll) values: [N] T = ---;

    new :: (roll: T, pitch: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = roll;
        result.values[1] = pitch;

        return result;
    }

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/vector.jai:40.
//
    x, y, z: T #align 16;
    #overlay (x) values: [N] T = ---;
    #overlay (x) xy: Vector(2, T, AXES) = ---;
    #overlay (y) yz: Vector(2, T, AXES) = ---;

    new :: (x: T, y: T, z: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = y;
        result.values[2] = z;

        return result;
    }

    new :: (x: T, yz: Vector(2, $T1, $A1)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = yz.values[0];
        result.values[2] = yz.values[1];

        return result;
    }

    new :: (xy: Vector(2, $T0, $A0), z: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = xy.values[0];
        result.values[1] = xy.values[1];
        result.values[2] = z;

        return result;
    }

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/vector.jai:40.
//
    x, y, z, w: T #align 16;
    #overlay (x) values: [N] T = ---;
    #overlay (x) xy: Vector(2, T, AXES) = ---;
    #overlay (y) yz: Vector(2, T, AXES) = ---;
    #overlay (z) zw: Vector(2, T, AXES) = ---;
    #overlay (x) xyz: Vector(3, T, AXES) = ---;
    #overlay (y) yzw: Vector(3, T, AXES) = ---;

    new :: (x: T, y: T, z: T, w: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = y;
        result.values[2] = z;
        result.values[3] = w;

        return result;
    }

    new :: (x: T, y: T, zw: Vector(2, $T2, $A2)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = y;
        result.values[2] = zw.values[0];
        result.values[3] = zw.values[1];

        return result;
    }

    new :: (x: T, yz: Vector(2, $T1, $A1), w: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = yz.values[0];
        result.values[2] = yz.values[1];
        result.values[3] = w;

        return result;
    }

    new :: (x: T, yzw: Vector(3, $T1, $A1)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = yzw.values[0];
        result.values[2] = yzw.values[1];
        result.values[3] = yzw.values[2];

        return result;
    }

    new :: (xy: Vector(2, $T0, $A0), z: T, w: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = xy.values[0];
        result.values[1] = xy.values[1];
        result.values[2] = z;
        result.values[3] = w;

        return result;
    }

    new :: (xy: Vector(2, $T0, $A0), zw: Vector(2, $T1, $A1)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = xy.values[0];
        result.values[1] = xy.values[1];
        result.values[2] = zw.values[0];
        result.values[3] = zw.values[1];

        return result;
    }

    new :: (xyz: Vector(3, $T0, $A0), w: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = xyz.values[0];
        result.values[1] = xyz.values[1];
        result.values[2] = xyz.values[2];
        result.values[3] = w;

        return result;
    }

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/vector.jai:40.
//
    x, y: T #align 16;
    #overlay (x) values: [N] T = ---;

    new :: (x: T, y: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = y;

        return result;
    }

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/vector.jai:40.
//
    x, y, z: T #align 16;
    #overlay (x) values: [N] T = ---;
    #overlay (x) xy: Vector(2, T, AXES) = ---;
    #overlay (y) yz: Vector(2, T, AXES) = ---;

    new :: (x: T, y: T, z: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = y;
        result.values[2] = z;

        return result;
    }

    new :: (x: T, yz: Vector(2, $T1, $A1)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = yz.values[0];
        result.values[2] = yz.values[1];

        return result;
    }

    new :: (xy: Vector(2, $T0, $A0), z: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = xy.values[0];
        result.values[1] = xy.values[1];
        result.values[2] = z;

        return result;
    }

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/vector.jai:40.
//
    x, y, z, w: T #align 16;
    #overlay (x) values: [N] T = ---;
    #overlay (x) xy: Vector(2, T, AXES) = ---;
    #overlay (y) yz: Vector(2, T, AXES) = ---;
    #overlay (z) zw: Vector(2, T, AXES) = ---;
    #overlay (x) xyz: Vector(3, T, AXES) = ---;
    #overlay (y) yzw: Vector(3, T, AXES) = ---;

    new :: (x: T, y: T, z: T, w: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = y;
        result.values[2] = z;
        result.values[3] = w;

        return result;
    }

    new :: (x: T, y: T, zw: Vector(2, $T2, $A2)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = y;
        result.values[2] = zw.values[0];
        result.values[3] = zw.values[1];

        return result;
    }

    new :: (x: T, yz: Vector(2, $T1, $A1), w: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = yz.values[0];
        result.values[2] = yz.values[1];
        result.values[3] = w;

        return result;
    }

    new :: (x: T, yzw: Vector(3, $T1, $A1)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = yzw.values[0];
        result.values[2] = yzw.values[1];
        result.values[3] = yzw.values[2];

        return result;
    }

    new :: (xy: Vector(2, $T0, $A0), z: T, w: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = xy.values[0];
        result.values[1] = xy.values[1];
        result.values[2] = z;
        result.values[3] = w;

        return result;
    }

    new :: (xy: Vector(2, $T0, $A0), zw: Vector(2, $T1, $A1)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = xy.values[0];
        result.values[1] = xy.values[1];
        result.values[2] = zw.values[0];
        result.values[3] = zw.values[1];

        return result;
    }

    new :: (xyz: Vector(3, $T0, $A0), w: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = xyz.values[0];
        result.values[1] = xyz.values[1];
        result.values[2] = xyz.values[2];
        result.values[3] = w;

        return result;
    }

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/vector.jai:40.
//
    x, y: T #align 16;
    #overlay (x) values: [N] T = ---;

    new :: (x: T, y: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = y;

        return result;
    }

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/vector.jai:40.
//
    x, y, z: T #align 16;
    #overlay (x) values: [N] T = ---;
    #overlay (x) xy: Vector(2, T, AXES) = ---;
    #overlay (y) yz: Vector(2, T, AXES) = ---;

    new :: (x: T, y: T, z: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = y;
        result.values[2] = z;

        return result;
    }

    new :: (x: T, yz: Vector(2, $T1, $A1)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = yz.values[0];
        result.values[2] = yz.values[1];

        return result;
    }

    new :: (xy: Vector(2, $T0, $A0), z: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = xy.values[0];
        result.values[1] = xy.values[1];
        result.values[2] = z;

        return result;
    }

//
// #insert text. Generated from /home/nick/Documents/Jay/engine/Jay_Math/types/vector.jai:40.
//
    x, y, z, w: T #align 16;
    #overlay (x) values: [N] T = ---;
    #overlay (x) xy: Vector(2, T, AXES) = ---;
    #overlay (y) yz: Vector(2, T, AXES) = ---;
    #overlay (z) zw: Vector(2, T, AXES) = ---;
    #overlay (x) xyz: Vector(3, T, AXES) = ---;
    #overlay (y) yzw: Vector(3, T, AXES) = ---;

    new :: (x: T, y: T, z: T, w: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = y;
        result.values[2] = z;
        result.values[3] = w;

        return result;
    }

    new :: (x: T, y: T, zw: Vector(2, $T2, $A2)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = y;
        result.values[2] = zw.values[0];
        result.values[3] = zw.values[1];

        return result;
    }

    new :: (x: T, yz: Vector(2, $T1, $A1), w: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = yz.values[0];
        result.values[2] = yz.values[1];
        result.values[3] = w;

        return result;
    }

    new :: (x: T, yzw: Vector(3, $T1, $A1)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = x;
        result.values[1] = yzw.values[0];
        result.values[2] = yzw.values[1];
        result.values[3] = yzw.values[2];

        return result;
    }

    new :: (xy: Vector(2, $T0, $A0), z: T, w: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = xy.values[0];
        result.values[1] = xy.values[1];
        result.values[2] = z;
        result.values[3] = w;

        return result;
    }

    new :: (xy: Vector(2, $T0, $A0), zw: Vector(2, $T1, $A1)) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = xy.values[0];
        result.values[1] = xy.values[1];
        result.values[2] = zw.values[0];
        result.values[3] = zw.values[1];

        return result;
    }

    new :: (xyz: Vector(3, $T0, $A0), w: T) -> Vector(N, T, AXES) {
        result: Vector(N, T, AXES);

        result.values[0] = xyz.values[0];
        result.values[1] = xyz.values[1];
        result.values[2] = xyz.values[2];
        result.values[3] = w;

        return result;
    }
