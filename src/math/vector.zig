const std = @import("std");
const tests = @import("tests");

pub fn zero(comptime N: comptime_int, comptime T: type) @Vector(N, T) {
    return @splat(0.0);
}

test "zero" {
    try std.testing.expect(eq(
        @Vector(2, f32){ 0.0, 0.0 },
        zero(2, f32),
    ));
}

pub fn unit(comptime N: comptime_int, T: type, i: usize) @Vector(N, T) {
    var u = zero(N, T);
    u = std.simd.shiftElementsRight(u, 1, 1);
    for (0..i) |_| {
        u = std.simd.rotateElementsRight(u, 1);
    }
    return u;
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

pub fn scaled(vec: anytype, c: typeInfo(@TypeOf(vec)).T) @TypeOf(vec) {
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
    return divided(vec, length(vec));
}

pub fn normalizedOrZero(vec: anytype, zero_threshold: typeInfo(@TypeOf(vec)).T) @TypeOf(vec) {
    if (approxZero(vec, zero_threshold))
        return zero(typeInfo(@TypeOf(vec)).N, typeInfo(@TypeOf(vec)).T);
    return normalized(vec);
}

pub fn normalizedOrNull(vec: anytype, zero_threshold: typeInfo(@TypeOf(vec)).T) ?@TypeOf(vec) {
    if (approxZero(vec, zero_threshold))
        return null;
    return normalized(vec);
}

test "normalized" {
    try std.testing.expect(eq(
        normalized(@Vector(4, f32){ 10.0, 0.0, 0.0, 0.0 }),
        @Vector(4, f32){ 1.0, 0.0, 0.0, 0.0 },
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

pub fn typeInfo(vecT: type) struct { N: comptime_int, T: type } {
    const info = @typeInfo(vecT).Vector;
    return .{ .N = info.len, .T = info.child };
}

pub fn approxZero(x: anytype, zero_threshold: typeInfo(@TypeOf(x)).T) bool {
    const tolerance: @TypeOf(x) = @splat(zero_threshold);

    //isNan(x)
    if (@reduce(.Or, x != x)) return false;

    return @reduce(.And, @abs(x) <= tolerance);
}

fn floatRange(rand: std.Random, T: type, from: T, to: T) T {
    return from + (to - from) * rand.float(T);
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
        v[i] = floatRange(rand, T, from, to);
    }
    return v;
}

pub fn fillRandomRange(
    N: comptime_int,
    T: type,
    vectors: []@Vector(N, T),
    rand: std.Random,
    from: T,
    to: T,
) void {
    for (0..vectors.len) |i| {
        vectors[i] = randomRange(N, T, rand, from, to);
    }
}

pub fn randomLinearlyDependent(
    N: comptime_int,
    T: type,
    dependent_on: []@Vector(N, T),
    rand: std.Random,
    from: T,
    to: T,
) @Vector(N, T) {
    var vec = zero(N, T);
    for (dependent_on) |d| {
        vec += scaled(d, floatRange(rand, T, from, to));
    }
    return vec;
}

pub fn randomNormal(N: comptime_int, T: type, rand: std.Random) @Vector(N, T) {
    std.debug.assert(@typeInfo(T) == .Float);
    const v: @Vector(N, T) = randomRange(N, T, rand, -1, 1);
    return normalized(v);
}

test "randomNormal" {
    const N = 3;
    const T = f32;

    const v = randomNormal(N, T, tests.RAND);

    for (0..N) |i| {
        try std.testing.expect(-1 <= v[i] and v[i] <= 1);
    }
}

pub fn randomNormalScaled(
    N: comptime_int,
    T: type,
    rand: std.Random,
    from: T,
    to: T,
) @Vector(N, T) {
    std.debug.assert(@typeInfo(T) == .Float);
    std.debug.assert(from < to);
    std.debug.assert(from >= 0);
    const v: @Vector(N, T) = randomNormal(N, T, rand);
    const c = floatRange(rand, T, from, to);
    return scaled(v, c);
}

test "randomNormalScaled" {
    const N = 3;
    const T = f32;
    const from: T = 0.1;
    const to: T = 10.0;

    const v = randomNormal(N, T, tests.RAND);
    const l = length(v);
    try std.testing.expect(from <= l);
    try std.testing.expect(l <= to);
}
