const std = @import("std");
const tests = @import("tests");
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

pub fn randomIntersecting(N: comptime_int, T: type, rand: std.Random) [2]AABB(N, T) {
    var points: [4]@Vector(N, T) = undefined;
    vector.fillRandomRange(N, T, &points, rand, -1, 1);
    for (0..3) |i| {
        for (0..3 - i) |j| {
            const minp = @min(points[j], points[j + 1]);
            const maxp = @max(points[j], points[j + 1]);
            points[j] = minp;
            points[j + 1] = maxp;
        }
    }
    var aabbs: [2]AABB(N, T) = undefined;
    aabbs[0] = AABB(N, T).new(points[0], points[2]);
    aabbs[1] = AABB(N, T).new(points[1], points[3]);
    return aabbs;
}

test "intersecting" {
    const N = 10;
    const T = f32;
    for (0..100000) |_| {
        const aabbs = randomIntersecting(N, T, tests.RAND);
        try std.testing.expect(aabbs[0].intersects(aabbs[1]));
    }
}

pub fn randomDisjoint(N: comptime_int, T: type, rand: std.Random) [2]AABB(N, T) {
    var points: [4]@Vector(N, T) = undefined;
    vector.fillRandomRange(N, T, &points, rand, -1, 1);
    var aabbs: [2]AABB(N, T) = undefined;
    aabbs[0] = AABB(N, T).new(
        @min(points[0], points[1]),
        @max(points[0], points[1]),
    );
    aabbs[1] = AABB(N, T).new(
        @min(points[2], points[3]),
        @max(points[2], points[3]),
    );
    const coord_i: usize = rand.intRangeLessThan(usize, 0, N);
    var coords: [4]T = .{
        points[0][coord_i],
        points[1][coord_i],
        points[2][coord_i],
        points[3][coord_i],
    };
    std.mem.sort(T, &coords, {}, std.sort.asc(T));
    const aabbs_i: usize = rand.intRangeLessThan(usize, 0, 2);
    aabbs[aabbs_i].bottom_left[coord_i] = coords[0];
    aabbs[aabbs_i].top_right[coord_i] = coords[1];
    aabbs[1 - aabbs_i].bottom_left[coord_i] = coords[2];
    aabbs[1 - aabbs_i].top_right[coord_i] = coords[3];
    return aabbs;
}

test "disjoint" {
    const N = 10;
    const T = f32;
    for (0..100000) |_| {
        const aabbs = randomDisjoint(N, T, tests.RAND);
        try std.testing.expect(!aabbs[0].intersects(aabbs[1]));
    }
}

pub fn randomAABBs(N: comptime_int, T: type, rand: std.Random) [2]AABB(N, T) {
    if (rand.boolean()) {
        return randomIntersecting(N, T, rand);
    } else {
        return randomDisjoint(N, T, rand);
    }
}
