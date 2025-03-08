const std = @import("std");
pub const matrix = @import("math/matrix.zig");
pub const vector = @import("math/vector.zig");

pub fn randFloatRange(T: type, from: T, to: T, rand: std.Random) T {
    std.debug.assert(from <= to);
    return from + (to - from) * rand.float(T);
}
