const std = @import("std");
const vector = @import("vector.zig");
const tests = @import("tests");

pub fn identity(N: comptime_int, T: type) [N]@Vector(N, T) {
    var m: [N]@Vector(N, T) = undefined;
    var u = vector.unit(N, T, 0);
    for (0..N - 1) |i| {
        m[i] = u;
        u = std.simd.rotateElementsRight(u, 1);
    }
    m[N - 1] = u;
    return m;
}

test "identity" {
    const N = 3;
    const T = f32;
    const expected: [3]@Vector(N, T) = .{
        .{ 1.0, 0.0, 0.0 },
        .{ 0.0, 1.0, 0.0 },
        .{ 0.0, 0.0, 1.0 },
    };
    const actual = identity(N, T);
    for (0..N) |i| {
        for (0..N) |j| {
            try std.testing.expectEqual(expected[i][j], actual[i][j]);
        }
    }
}

pub fn transpose(
    M: comptime_int,
    N: comptime_int,
    T: type,
    rows: [M]@Vector(N, T),
) [N]@Vector(M, T) {
    var matrix: [N]@Vector(M, T) = undefined;
    for (0..N) |n| {
        for (0..M) |m| {
            matrix[n][m] = rows[m][n];
        }
    }
    return matrix;
}

test "transpose" {
    const rows = [2]@Vector(3, f32){
        .{ 1.0, 1.0, 0.0 },
        .{ 0.0, 1.0, 0.0 },
    };
    const expected = [3]@Vector(2, f32){
        .{ 1.0, 0.0 },
        .{ 1.0, 1.0 },
        .{ 0.0, 0.0 },
    };
    const actual = transpose(2, 3, f32, rows);
    for (0..2) |i| {
        for (0..3) |j| {
            try std.testing.expectEqual(expected[j][i], actual[j][i]);
        }
    }
}
