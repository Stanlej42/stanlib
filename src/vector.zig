const std = @import("std");
const tests = @import("tests");
const approx = @import("math").approx;

pub fn zero(comptime N: comptime_int, comptime T: type) @Vector(N, T) {
    return @splat(0.0);
}

test "zero" {
    try std.testing.expect(eq(
        @Vector(2, f32){ 0.0, 0.0 },
        zero(2, f32),
    ));
}

pub fn eq(a: anytype, b: anytype) bool {
    return @reduce(.And, a == b);
}

test "eq" {
    try std.testing.expect(eq(
        @Vector(2, f32){ 1.0, 0.0 },
        @Vector(2, f32){ 1.0, 0.0 },
    ));

    try std.testing.expect(!eq(
        @Vector(2, f32){ 1.0, 0.0 },
        @Vector(2, f32){ 0.0, 1.0 },
    ));
}

pub fn dot(a: anytype, b: anytype) @typeInfo(@TypeOf(a, b)).Vector.child {
    return @reduce(.Add, a * b);
}

test "dot" {
    try std.testing.expectEqual(-8.0, dot(
        @Vector(2, f32){ 2.0, -1.0 },
        @Vector(2, f32){ -3.0, 2.0 },
    ));
}

pub fn scaled(vec: anytype, c: @typeInfo(@TypeOf(vec)).Vector.child) @TypeOf(vec) {
    return vec * @as(@TypeOf(vec), @splat(c));
}

test "scaled" {
    var v = @Vector(3, f32){ 1.0, 0.5, -0.25 };
    v = scaled(v, 2);
    try std.testing.expectEqual(2, v[0]);
    try std.testing.expectEqual(1, v[1]);
    try std.testing.expectEqual(-0.5, v[2]);
}

pub fn divided(vec: anytype, c: @typeInfo(@TypeOf(vec)).Vector.child) @TypeOf(vec) {
    return vec / @as(@TypeOf(vec), @splat(c));
}

test "divided" {
    var v = @Vector(3, f32){ 1.0, 0.5, -0.25 };
    v = divided(v, 2);
    try std.testing.expectEqual(0.5, v[0]);
    try std.testing.expectEqual(0.25, v[1]);
    try std.testing.expectEqual(-0.125, v[2]);
}

pub fn length(vec: anytype) @typeInfo(@TypeOf(vec)).Vector.child {
    return @sqrt(dot(vec, vec));
}

test "length" {
    try std.testing.expectEqual(@sqrt(3.0), length(@Vector(3, f32){ 1.0, 1.0, 1.0 }));
}

pub fn normalized(vec: anytype) @TypeOf(vec) {
    std.debug.assert(!approxZeroAbs(vec));
    return divided(vec, length(vec));
}

test "normalized" {
    try std.testing.expect(eq(
        normalized(@Vector(4, f32){ 10.0, 0.0, 0.0, 0.0 }),
        @Vector(4, f32){ 1.0, 0.0, 0.0, 0.0 },
    ));
}

pub fn normalizedOrZero(vec: anytype) @TypeOf(vec) {
    if (!approxZeroAbs(vec)) {
        return normalized(vec);
    }
    const N = @typeInfo(@TypeOf(vec)).Vector.len;
    const T = @typeInfo(@TypeOf(vec)).Vector.child;
    return zero(N, T);
}

test "normalizedOrZero" {
    try std.testing.expect(eq(
        normalizedOrZero(@Vector(4, f32){ std.math.floatEps(f32), 0.0, 0.0, 0.0 }),
        @Vector(4, f32){ 0.0, 0.0, 0.0, 0.0 },
    ));
}

pub fn projected(vec: anytype, onto: anytype) @TypeOf(vec, onto) {
    return divided(
        scaled(
            onto,
            dot(vec, onto),
        ),
        dot(onto, onto),
    );
}

test "projected" {
    try std.testing.expect(eq(
        projected(
            @Vector(2, f32){ 1.0, 1.0 },
            @Vector(2, f32){ 2.0, 0.0 },
        ),
        @Vector(2, f32){ 1.0, 0.0 },
    ));
}

pub fn anyNan(x: anytype) bool {
    return @reduce(.Or, x != x);
}

pub fn approxZeroAbs(x: anytype) bool {
    const N = @typeInfo(@TypeOf(x)).Vector.len;
    const T = @typeInfo(@TypeOf(x)).Vector.child;

    return approxEqAbs(zero(N, T), x);
}

pub fn approxZeroRel(x: anytype) bool {
    const N = @typeInfo(@TypeOf(x)).Vector.len;
    const T = @typeInfo(@TypeOf(x)).Vector.child;

    return approxEqRel(zero(N, T), x);
}

test "approxZero" {
    try std.testing.expect(approxZeroAbs(@Vector(2, f32){ 0.0, 0.0 }));
    try std.testing.expect(approxZeroAbs(@Vector(2, f32){ std.math.floatEps(f32), 0.0 }));
    try std.testing.expect(approxZeroAbs(@Vector(2, f32){ -std.math.floatEps(f32), -std.math.floatEps(f32) }));
    try std.testing.expect(!approxZeroAbs(@Vector(2, f32){ -std.math.floatEps(f32), -2 * std.math.floatEps(f32) }));
    try std.testing.expect(!approxZeroAbs(@Vector(2, f32){ -std.math.floatEps(f32), std.math.nan(f32) }));
}

pub fn approxEqAbs(expected: anytype, actual: @TypeOf(expected)) bool {
    const T = @typeInfo(@TypeOf(expected)).Vector.child;
    std.debug.assert(@typeInfo(T) == .Float or @typeInfo(T) == .ComptimeFloat);

    if (anyNan(expected))
        return false;

    return @reduce(.And, @abs(expected - actual) <= @as(@TypeOf(expected), @splat(std.math.floatEps(T))));
}

pub fn approxEqRel(expected: anytype, actual: @TypeOf(expected)) bool {
    const T = @typeInfo(@TypeOf(expected)).Vector.child;
    std.debug.assert(@typeInfo(T) == .Float or @typeInfo(T) == .ComptimeFloat);

    if (anyNan(expected))
        return false;

    const tolerance: @TypeOf(expected) = @splat(@sqrt(std.math.floatEps(T)));
    return @reduce(.And, @abs(expected - actual) <= @max(@abs(expected), @abs(actual)) * tolerance);
}

pub fn random(N: comptime_int, T: type, rand: std.Random) @Vector(N, T) {
    std.debug.assert(@typeInfo(T) == .Float);
    var v: @Vector(N, T) = undefined;
    for (0..N) |i| {
        v[i] = rand.float(T);
    }
    return v;
}

pub fn randomRange(
    N: comptime_int,
    T: type,
    rand: std.Random,
    from: T,
    to: T,
) @Vector(N, T) {
    std.debug.assert(@typeInfo(T) == .Float);
    var v: @Vector(N, T) = undefined;
    for (0..N) |i| {
        v[i] = from + (to - from) * rand.float(T);
    }
    return v;
}

pub fn randomUnit(N: comptime_int, T: type, rand: std.Random) @Vector(N, T) {
    std.debug.assert(@typeInfo(T) == .Float);
    var v: @Vector(N, T) = undefined;
    for (0..N) |i| {
        v[i] = 2 * rand.float(T) - 1;
    }
    return normalized(v);
}

test "randomUnit" {
    const N = 3;
    const T = f32;

    const v = randomUnit(N, T, tests.RAND);

    for (0..N) |i| {
        try std.testing.expect(-1 <= v[i] and v[i] <= 1);
    }
    try std.testing.expect(approx.approxEqAbs(T, 1.0, length(v)));
}

pub fn randomUnitScaled(
    N: comptime_int,
    T: type,
    rand: std.Random,
    from: T,
    to: T,
) @Vector(N, T) {
    std.debug.assert(@typeInfo(T) == .Float);
    std.debug.assert(from < to);
    std.debug.assert(from >= 0);
    var v: @Vector(N, T) = undefined;
    for (0..N) |i| {
        v[i] = 2 * rand.float(T) - 1;
    }
    const c = to + (from - to) * rand.float(T);
    return scaled(normalized(v), c);
}

test "randomUnitRange" {
    const N = 3;
    const T = f32;
    const from: T = 0.1;
    const to: T = 10.0;

    const v = randomUnit(N, T, tests.RAND);
    const l = length(v);
    try std.testing.expect(from <= l);
    try std.testing.expect(l <= to);
}
