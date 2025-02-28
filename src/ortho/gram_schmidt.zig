const std = @import("std");
const vector = @import("math").vector;
const tests = @import("tests");

fn MGS(
    N: comptime_int,
    T: type,
    vec: @Vector(N, T),
    orthonormal: []@Vector(N, T),
) @Vector(N, T) {
    return MGSoi(N, T, vec, orthonormal, 1, 1);
}

fn MGS2_(
    N: comptime_int,
    T: type,
    vec: @Vector(N, T),
    orthonormal: []@Vector(N, T),
) @Vector(N, T) {
    return MGSoi(N, T, vec, orthonormal, 2, 1);
}

fn MGSoi(
    N: comptime_int,
    T: type,
    vec: @Vector(N, T),
    orthonormal: []@Vector(N, T),
    outer: comptime_int,
    inner: comptime_int,
) @Vector(N, T) {
    var new = vec;
    for (0..outer) |_| {
        for (orthonormal) |o| {
            for (0..inner) |_| {
                const c = vector.dot(o, new);
                new -= vector.scaled(o, c);
            }
        }
    }
    return new;
}

fn threshold(
    N: comptime_int,
    T: type,
) T {
    const flN: T = @floatFromInt(N);
    _ = flN;
    // return @sqrt(flN) * std.math.floatEps(T);
    return 2 * std.math.floatEps(T);
}

pub fn orthogonalizeOne(
    N: comptime_int,
    T: type,
    vec: @Vector(N, T),
    orthonormal: []@Vector(N, T),
) @Vector(N, T) {
    const new = vector.normalizedOrZero(vec, threshold(N, T));
    return MGS2_(N, T, new, orthonormal);
}

pub fn orthonormalizeOne(
    N: comptime_int,
    T: type,
    vec: @Vector(N, T),
    orthonormal: []@Vector(N, T),
) ?@Vector(N, T) {
    return vector.normalizedOrNull(
        orthogonalizeOne(N, T, vec, orthonormal),
        threshold(N, T),
    );
}

pub fn orthonormalize(
    N: comptime_int,
    T: type,
    vecs: []@Vector(N, T),
) void {
    for (0..2) |_| {
        for (0..vecs.len) |i| {
            vecs[i] = orthonormalizeOne(N, T, vecs[i], vecs[0..i]) orelse
                vector.zero(N, T);
        }
    }
}

test "orthogonality" {
    // if (true) return error.SkipZigTest;
    const N = 10;
    const T = f32;
    var max_dot: T = 0;
    for (0..100000) |_| {
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
    // if (true) return error.SkipZigTest;
    const N = 10;
    const T = f32;
    var max_error: T = 0;
    for (0..100000) |_| {
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
