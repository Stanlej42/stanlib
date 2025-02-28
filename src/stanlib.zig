pub const math = @import("math.zig");
pub const ortho = @import("ortho.zig");
pub const collision = @import("collision.zig");

const std = @import("std");
const tests = @import("tests");

test {
    tests.PRNG = std.Random.DefaultPrng.init(std.crypto.random.int(u64));
    tests.RAND = tests.PRNG.random();
    std.testing.refAllDeclsRecursive(struct {
        pub const math = @import("math.zig");
        pub const ortho = @import("ortho.zig");
        // pub const collision = @import("collision.zig");
    });
}
