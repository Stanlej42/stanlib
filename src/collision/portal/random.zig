const std = @import("std");
const math = @import("stanlib").math;
const vector = math.vector;
const Portal = @import("../Portal.zig").Portal;

pub fn portal(
    N: comptime_int,
    T: type,
    rand: std.Random,
) Portal(N, T) {
    var p = Portal(N, T).new(
        vector.randomRange(N, T, rand, -1, 1),
    );
    for (0..N) |i| {
        p.setPoint(
            i,
            vector.randomRange(N, T, rand, -1, 1),
        );
    }
    return p;
}

fn interiorPoint(
    N: comptime_int,
    T: type,
    rand: std.Random,
    p: Portal(N, T),
) @Vector(N, T) {
    var c: T = undefined;
    var total: T = 0;
    var point = vector.zero(N, T);
    for (0..N) |i| {
        c = math.randFloatRange(T, 0, 1, rand);
        total += c;
        point += vector.scaled(p.points[i], c);
    }
    c = math.randFloatRange(T, 0, 1, rand);
    total += c;
    point += vector.scaled(p.base_point, c);
    return vector.divided(point, total);
}

fn portalPoint(
    N: comptime_int,
    T: type,
    rand: std.Random,
    p: Portal(N, T),
) @Vector(N, T) {
    var c: T = undefined;
    var total: T = 0;
    var point = vector.zero(N, T);
    for (0..N) |i| {
        c = math.randFloatRange(T, 0, 1, rand);
        total += c;
        point += vector.scaled(p.points[i], c);
    }
    return vector.divided(point, total);
}

pub fn containingOrigin(
    N: comptime_int,
    T: type,
    rand: std.Random,
) Portal(N, T) {
    var p = portal(N, T, rand);
    const in = interiorPoint(N, T, rand, p);
    p.translate(-in);
    return p;
}

pub fn intersectingORay(
    N: comptime_int,
    T: type,
    rand: std.Random,
) Portal(N, T) {
    var p = containingOrigin(N, T, rand);
    var newO = portalPoint(N, T, rand, p) - p.base_point;
    newO = vector.scaled(newO, math.randFloatRange(T, 0, 2, rand));
    p.translate(-newO);
    return p;
}

pub fn intersectingNotContaining(
    N: comptime_int,
    T: type,
    rand: std.Random,
) Portal(N, T) {
    var p = containingOrigin(N, T, rand);
    p.translate(-refinePoint(N, T, p, rand));
    return p;
}

pub fn refinePoint(
    N: comptime_int,
    T: type,
    p: Portal(N, T),
    rand: std.Random,
) @Vector(N, T) {
    var rp = portalPoint(N, T, rand, p) - p.base_point;
    rp = vector.scaled(rp, 1 + math.randFloatRange(T, 2 * std.math.floatEps(T), 1, rand));
    return rp;
}
