const std = @import("std");
const vector = @import("math").vector;
const approx = @import("math").approx;
const tests = @import("tests");

pub fn orthogonalizeToUnit(
    N: comptime_int,
    T: type,
    orthonormal_set: []const @Vector(N, T),
    vec: @Vector(N, T),
) @Vector(N, T) {
    std.debug.assert(orthonormal_set.len < N);
    var new = vec;
    for (orthonormal_set) |normal| {
        const c = vector.dot(new, normal);
        new -= vector.scaled(normal, c);
    }
    return new;
}

pub fn gramSchmidtOne(
    N: comptime_int,
    T: type,
    orthonormal_set: []const @Vector(N, T),
    v: @Vector(N, T),
) @Vector(N, T) {
    var new = vector.normalizedOrZero(v);
    switch (orthonormal_set.len) {
        inline 0 => {},
        else => {
            for (0..2) |_| {
                new = orthogonalizeToUnit(N, T, orthonormal_set, new);
            }
            new = vector.normalizedOrZero(new);
        },
    }
    return new;
}

pub fn gramSchmidt(
    N: comptime_int,
    T: type,
    set: []@Vector(N, T),
) void {
    std.debug.assert(set.len <= N);
    set[0] = vector.normalizedOrZero(set[0]);
    for (1..set.len) |i| {
        set[i] = gramSchmidtOne(N, T, set[0..i], set[i]);
    }
}

test "gramSchmidt" {
    const N = 10;
    const T = f32;

    var vectors: [N]@Vector(N, T) = undefined;
    for (&vectors) |*v| {
        v.* = vector.randomUnitScaled(N, T, tests.RAND, 0.0000001, 10000.0);
    }

    gramSchmidt(N, T, &vectors);

    for (1..N) |i| {
        try std.testing.expect(approx.approxEqAbs(T, 1.0, vector.length(vectors[i])));
        for (0..i) |j| {
            const c = vector.dot(vectors[i], vectors[j]);
            try std.testing.expect(approx.approxZero(T, c));
        }
        for (i + 1..N) |j| {
            const c = vector.dot(vectors[i], vectors[j]);
            try std.testing.expect(approx.approxZero(T, c));
        }
    }
}
