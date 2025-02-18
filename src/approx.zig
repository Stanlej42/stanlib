const std = @import("std");

pub fn approxZero(T: type, value: T) bool {
    return std.math.approxEqAbs(T, 0, value, std.math.floatEps(T));
}

test "approxZero" {
    try std.testing.expect(approxZero(f32, 0.0));
    try std.testing.expect(approxZero(f32, std.math.floatEps(f32)));
    try std.testing.expect(approxZero(f32, -std.math.floatEps(f32)));
}

pub fn approxEqAbs(T: type, expected: T, actual: T) bool {
    std.debug.assert(std.math.isNormal(expected));
    return std.math.approxEqAbs(T, expected, actual, std.math.floatEpsAt(T, expected));
}

test "approxEqAbs" {
    try std.testing.expect(approxEqAbs(f32, 1.0, 1.0));
    try std.testing.expect(approxEqAbs(f32, 1.0, 1.0 + std.math.floatEps(f32)));
    try std.testing.expect(approxEqAbs(f32, 2.0, 2.0 - std.math.floatEps(f32)));
}

pub fn approxEqRel(T: type, expected: T, actual: T) bool {
    return std.math.approxEqRel(T, expected, actual, @sqrt(std.math.floatEps(T)));
}
