const std = @import("std");
const vector = @import("math").vector;
const tests = @import("tests");

pub fn identity(N: comptime_int, T: type) [N]@Vector(N, T) {
    var m: [N]@Vector(N, T) = undefined;
    for (0..N) |i| {
        m[i] = vector.zero(N, T);
        m[i][i] = 1;
    }
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

pub fn mulRowColToRow(
    N: comptime_int,
    P: comptime_int,
    T: type,
    rows: []const @Vector(N, T),
    cols: [P]@Vector(N, T),
    dest_rows: []@Vector(P, T),
) void {
    std.debug.assert(rows.len == dest_rows.len);
    for (0..rows.len) |r| {
        for (0..P) |c| {
            dest_rows[r][c] = vector.dot(rows[r], cols[c]);
        }
    }
}

pub fn mulRowColToCol(
    M: comptime_int,
    N: comptime_int,
    T: type,
    rows: [M]@Vector(N, T),
    cols: []const @Vector(N, T),
    dest_cols: []@Vector(M, T),
) void {
    std.debug.assert(cols.len == dest_cols.len);
    for (0..M) |r| {
        for (0..cols.len) |c| {
            dest_cols[c][r] = vector.dot(rows[r], cols[c]);
        }
    }
}

test "mul" {
    const M = 4;
    const N = 3;
    const P = 2;
    const T = f32;
    const rows = [M]@Vector(N, T){
        vector.randomUnit(N, T, tests.RAND),
        vector.randomUnit(N, T, tests.RAND),
        vector.randomUnit(N, T, tests.RAND),
        vector.randomUnit(N, T, tests.RAND),
    };
    const cols = [P]@Vector(N, T){
        vector.randomUnit(N, T, tests.RAND),
        vector.randomUnit(N, T, tests.RAND),
    };
    var dest_rows: [M]@Vector(P, T) = undefined;
    var dest_cols: [P]@Vector(M, T) = undefined;
    mulRowColToRow(N, P, T, &rows, cols, &dest_rows);
    mulRowColToCol(M, N, T, rows, &cols, &dest_cols);
    for (0..M) |m| {
        for (0..P) |p| {
            try std.testing.expectEqual(dest_rows[m][p], dest_cols[p][m]);
        }
    }
}
