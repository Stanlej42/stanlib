const std = @import("std");
const vector = @import("math").vector;
const tests = @import("tests");

fn MGS(
    N: comptime_int,
    T: type,
    vec: @Vector(N, T),
    orthonormal: []@Vector(N, T),
) @Vector(N, T) {
    var new = vec;
    for (orthonormal) |o| {
        const c = vector.dot(o, new);
        new -= vector.scaled(o, c);
    }
    return new;
}

fn MGS2(
    N: comptime_int,
    T: type,
    vec: @Vector(N, T),
    orthonormal: []@Vector(N, T),
) @Vector(N, T) {
    var new = vec;
    for (orthonormal) |o| {
        for (0..2) |_| {
            const c = vector.dot(o, new);
            new -= vector.scaled(o, c);
        }
    }
    return new;
}

fn MGS22(
    N: comptime_int,
    T: type,
    vec: @Vector(N, T),
    orthonormal: []@Vector(N, T),
) @Vector(N, T) {
    var new = vec;
    // var new = vector.normalized(vec);
    for (0..2) |_| {
        for (orthonormal) |o| {
            for (0..2) |_| {
                const c = vector.dot(o, new);
                new -= vector.scaled(o, c);
            }
        }
    }
    return new;
}

pub fn orthogonalizeOne(
    N: comptime_int,
    T: type,
    vec: @Vector(N, T),
    orthonormal: []@Vector(N, T),
) @Vector(N, T) {
    return MGS22(N, T, vec, orthonormal);
}

fn orthonormalizeThreshold(
    N: comptime_int,
    T: type,
    vecs: []@Vector(N, T),
    zero_threshold: T,
) void {
    vecs[0] = vector.normalizedOrZero(vecs[0], zero_threshold);
    for (0..vecs.len) |i| {
        vecs[i] = vector.normalizedOrZero(
            orthogonalizeOne(N, T, vecs[i], vecs[0..i]),
            zero_threshold,
        );
    }
}

fn threshold(
    N: comptime_int,
    T: type,
) T {
    const flN: T = @floatFromInt(N);
    return @sqrt(2 * flN) * std.math.floatEps(T);
}

pub fn orthonormalize(
    N: comptime_int,
    T: type,
    vecs: []@Vector(N, T),
) void {
    orthonormalizeThreshold(N, T, vecs, threshold(N, T));
}

test "orthogonality" {
    if (true) return error.SkipZigTest;
    const N = 4;
    const T = f32;
    var max_dot: T = 0;
    for (0..1000000) |_| {
        var vecs: [N]@Vector(N, T) = undefined;
        vector.fillRandomRange(N, T, &vecs, tests.RAND, -1, 1);
        orthonormalize(N, T, &vecs);
        for (0..vecs.len - 1) |i| {
            for (i + 1..vecs.len) |j| {
                const dot = @abs(vector.dot(vecs[i], vecs[j]));
                max_dot = @max(max_dot, dot);
            }
        }
    }
    try std.testing.expectApproxEqAbs(0, max_dot, threshold(N, T));
    std.debug.print("max dot    : {d}\n", .{max_dot});
    std.debug.print("threshold  : {d}\n", .{threshold(N, T)});
}

test "linearly dependent" {
    if (true) return error.SkipZigTest;
    const N = 4;
    const T = f32;
    var max_error: T = 0;
    for (0..1000000) |_| {
        var vecs: [N]@Vector(N, T) = undefined;
        vector.fillRandomRange(N, T, vecs[0 .. N - 1], tests.RAND, -1, 1);
        vecs[N - 1] = vector.randomLinearlyDependent(N, T, vecs[0 .. N - 1], tests.RAND, -1, 1);
        orthonormalize(N, T, vecs[0 .. N - 1]);
        vecs[N - 1] = orthogonalizeOne(N, T, vecs[N - 1], vecs[0 .. N - 1]);
        const err = @reduce(.Max, @abs(vecs[N - 1]));
        max_error = @max(max_error, err);
    }

    try std.testing.expectApproxEqAbs(0, max_error, threshold(N, T));
    std.debug.print("max error  : {d}\n", .{max_error});
    std.debug.print("threshold  : {d}\n", .{threshold(N, T)});
}
