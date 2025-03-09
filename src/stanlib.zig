pub const math = @import("math.zig");
pub const ortho = @import("ortho.zig");
pub const collision = @import("collision.zig");

const std = @import("std");
const tests = @import("tests");

test {
    tests.init();
    std.testing.refAllDeclsRecursive(@This());
}
