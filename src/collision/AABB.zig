const std = @import("std");
const vector = @import("stanlib").math.vector;

pub fn AABB(comptime N: comptime_int, comptime T: type) type {
    return struct {
        const Self: type = @This();

        bottom_left: @Vector(N, T),
        top_right: @Vector(N, T),

        pub fn new(bottom_left: @Vector(N, T), top_right: @Vector(N, T)) Self {
            const self = Self{
                .bottom_left = bottom_left,
                .top_right = top_right,
            };
            std.debug.assert(self.isCorrect());
            return self;
        }

        pub fn intersects(self: Self, other: Self) bool {
            return @reduce(.And, self.bottom_left <= other.top_right) and
                @reduce(.And, other.bottom_left <= self.top_right);
        }

        pub fn contains(self: Self, point: @Vector(N, T)) bool {
            return @reduce(.And, self.bottom_left <= point) and
                @reduce(.And, point <= self.top_right);
        }

        pub fn support(self: Self, direction: @Vector(N, T)) @Vector(N, T) {
            return @select(
                T,
                direction < vector.zero(N, T),
                self.bottom_left,
                self.top_right,
            );
        }

        pub fn interior(self: Self) @Vector(N, T) {
            return (self.bottom_left + self.top_right) / @as(@Vector(N, T), @splat(2));
        }

        pub fn isCorrect(self: Self) bool {
            return @reduce(.And, self.bottom_left <= self.top_right);
        }
    };
}

test {
    const N = 2;
    const T = f32;
    const aabb1 = AABB(N, T).new(.{ -1.0, -1.0 }, .{ 1.0, 1.0 });
    const aabb2 = AABB(N, T).new(.{ 0.0, 0.0 }, .{ 2.0, 2.0 });
    try std.testing.expect(aabb1.intersects(aabb2));
    try std.testing.expect(aabb2.intersects(aabb1));
    try std.testing.expectEqual(@Vector(N, T){ 0.0, 0.0 }, aabb1.interior());
    try std.testing.expectEqual(@Vector(N, T){ 1.0, 1.0 }, aabb2.interior());
    try std.testing.expectEqual(@Vector(N, T){ 0.0, 2.0 }, aabb2.support(.{ -1.0, 1.0 }));
}
