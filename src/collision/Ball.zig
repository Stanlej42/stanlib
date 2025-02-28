const std = @import("std");
const vector = @import("stanlib").math.vector;

pub fn Ball(comptime N: comptime_int, comptime T: type) type {
    return struct {
        const Self: type = @This();

        pos: @Vector(N, T),
        radius: T,

        pub fn new(pos: @Vector(N, T), radius: T) Self {
            std.debug.assert(radius > 0);
            return .{
                .pos = pos,
                .radius = radius,
            };
        }

        pub fn intersects(self: Self, other: Self) bool {
            const pointing = self.pos - other.pos;

            return vector.length(pointing) <= self.radius + other.radius;
        }

        pub fn contains(self: Self, point: @Vector(N, T)) bool {
            const r = self.pos - point;
            return vector.dot(r, r) <= self.radius * self.radius;
        }

        pub fn support(self: Self, direction: @Vector(N, T)) @Vector(N, T) {
            return self.pos + vector.scaled(direction, self.radius);
        }

        pub fn interior(self: Self) @Vector(N, T) {
            return self.pos;
        }
    };
}
