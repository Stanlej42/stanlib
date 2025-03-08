const std = @import("std");

const stanlib = @import("stanlib");

pub var PRNG: std.Random.DefaultPrng = undefined;
pub var RAND: std.Random = undefined;

pub fn init() void {
    PRNG = std.Random.DefaultPrng.init(std.crypto.random.int(u64));
    RAND = PRNG.random();
}
