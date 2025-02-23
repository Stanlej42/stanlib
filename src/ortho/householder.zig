const std = @import("std");
const vector = @import("math").vector;
const tests = @import("tests");

fn reflected(
    N: comptime_int,
    T: type,
    point: @Vector(N, T),
    normal: @Vector(N, T),
) @Vector(N, T) {
    const c = 2 * vector.dot(normal, point);
    return point - vector.scaled(normal, c);
}

fn householderNormal(
    N: comptime_int,
    T: type,
    vec: @Vector(N, T),
    coord: usize,
    zero_threshold: T,
) @Vector(N, T) {
    var normal = vec;
    const sign: T = if (vec[coord] < 0) -1 else 1;
    normal[coord] += sign * vector.length(vec);
    return vector.normalizedOrZero(normal, zero_threshold);
}

fn householderOne(
    N: comptime_int,
    T: type,
    vec: @Vector(N, T),
    normals: []@Vector(N, T),
) @Vector(N, T) {
    var new = vec;
    for (0..normals.len) |i| {
        new = reflected(N, T, new, normals[i]);
        new[i] = 0;
        // new = reflected(N, T, new, normals[i]);
    }
    return new;
}

fn householder(
    N: comptime_int,
    T: type,
    vecs: []@Vector(N, T),
    normals: []@Vector(N, T),
    zero_threshold: T,
) void {
    std.debug.assert(vecs.len == normals.len);
    for (0..vecs.len) |i| {
        vecs[i] = householderOne(N, T, vecs[i], normals[0..i]);
        normals[i] = householderNormal(N, T, vecs[i], i, zero_threshold);
        vecs[i] = vector.unit(N, T, i);
        for (0..i + 1) |j| {
            vecs[i] = reflected(N, T, vecs[i], normals[i - j]);
        }
    }
}

fn threshold(N: comptime_int, T: type) T {
    _ = N;
    return 7 * std.math.floatEps(T);
}

test {
    if (true) return error.SkipZigTest;
    const N = 3;
    const T = f32;
    var vecs: [N]@Vector(N, T) = undefined;
    // var vecs: [N]@Vector(N, T) = .{
    //     .{ 12, 6, -4 },
    //     .{ -51, 167, 24 },
    //     .{ 4, -68, -41 },
    // };
    var normals: [N]@Vector(N, T) = undefined;
    var normals2: [N]@Vector(N, T) = undefined;
    vector.fillRandomRange(N, T, &vecs, tests.RAND, -1, 1);
    var vecs2 = vecs;
    std.debug.print("{d}\n", .{vecs});
    // normals[2] = householderNormal(N, T, vecs[2], 2, threshold(N, T));
    // vecs[0] = reflected(N, T, vecs[0], normals[0]);
    // vecs[0] = vector.zero(N, T);
    // vecs[0][0] = 1;
    normals[0] = householderNormal(N, T, vecs[0], 0, threshold(N, T));
    // std.debug.print("{d}\n", .{reflected(N, T, vecs[0], normals[0])});
    vecs[0] = vector.unit(N, T, 0);
    vecs[0] = reflected(N, T, vecs[0], normals[0]);

    vecs[1] = reflected(N, T, vecs[1], normals[0]);
    vecs[1][0] = 0;
    normals[1] = householderNormal(N, T, vecs[1], 1, threshold(N, T));
    vecs[1] = vector.unit(N, T, 1);
    vecs[1] = reflected(N, T, vecs[1], normals[1]);
    vecs[1] = reflected(N, T, vecs[1], normals[0]);

    vecs[2] = reflected(N, T, vecs[2], normals[0]);
    vecs[2][0] = 0;
    vecs[2] = reflected(N, T, vecs[2], normals[1]);
    vecs[2][1] = 0;
    normals[2] = householderNormal(N, T, vecs[2], 2, threshold(N, T));
    vecs[2] = vector.unit(N, T, 2);
    vecs[2] = reflected(N, T, vecs[2], normals[2]);
    vecs[2] = reflected(N, T, vecs[2], normals[1]);
    vecs[2] = reflected(N, T, vecs[2], normals[0]);
    // vecs[1] = reflected(N, T, vecs[1], normals[1]);
    // vecs[1] = vector.zero(N, T);
    // vecs[1][1] = 1;
    // vecs[1] = reflected(N, T, vecs[1], normals[0]);
    // vecs[2] = vector.zero(N, T);
    // vecs[2][2] = 1;
    // vecs[2] = reflected(N, T, vecs[2], normals[0]);
    householder(N, T, &vecs2, &normals2, threshold(N, T));
    std.debug.print("{d}\n", .{vecs});
    std.debug.print("N{d}\n", .{normals});
    std.debug.print("{d}\n", .{vecs2});
    std.debug.print("N{d}\n", .{normals2});
    for (0..vecs.len - 1) |i| {
        for (i + 1..vecs.len) |j| {
            const dot = @abs(vector.dot(vecs[i], vecs[j]));
            std.debug.print("{d}\n", .{dot});
        }
    }
}

test "orthogonality" {
    // if (true) return error.SkipZigTest;
    const N = 4;
    const T = f32;
    var max_dot: T = 0;
    for (0..1000000) |_| {
        var vecs: [N]@Vector(N, T) = undefined;
        var normals: [N]@Vector(N, T) = undefined;
        vector.fillRandomRange(N, T, &vecs, tests.RAND, -1, 1);
        householder(N, T, &vecs, &normals, threshold(N, T));
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
    const N = 4;
    const T = f32;
    var max_error: T = 0;
    for (0..1000000) |_| {
        var vecs: [N]@Vector(N, T) = undefined;
        var normals: [N]@Vector(N, T) = undefined;
        vector.fillRandomRange(N, T, vecs[0 .. N - 1], tests.RAND, -1, 1);
        vecs[N - 1] = vector.randomLinearlyDependent(N, T, vecs[0 .. N - 1], tests.RAND, -1, 1);
        householder(N, T, vecs[0 .. N - 1], normals[0 .. N - 1], threshold(N, T));
        vecs[N - 1] = householderOne(N, T, vecs[N - 1], normals[0 .. N - 1]);
        const err = @reduce(.Max, @abs(vecs[N - 1]));
        max_error = @max(max_error, err);
    }

    try std.testing.expectApproxEqAbs(0, max_error, threshold(N, T));
    std.debug.print("max error  : {d}\n", .{max_error});
    std.debug.print("threshold  : {d}\n", .{threshold(N, T)});
}
