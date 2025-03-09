const std = @import("std");
const tests = @import("tests");
const math = @import("stanlib").math;
const vector = math.vector;
const ortho = @import("stanlib").ortho;
const random = @import("portal/random.zig");

pub fn Portal(N: comptime_int, T: type) type {
    return struct {
        base_point: @Vector(N, T),
        points: [N]@Vector(N, T),
        base_edges: [N]@Vector(N, T),

        const Self = @This();

        pub fn new(base_point: @Vector(N, T)) Self {
            return .{
                .base_point = base_point,
                .points = undefined,
                .base_edges = undefined,
            };
        }

        pub fn setPoint(self: *Self, i: usize, point: @Vector(N, T)) void {
            std.debug.assert(i < N);
            self.points[i] = point;
            self.base_edges[i] = point - self.base_point;
        }

        pub fn setEdge(self: *Self, i: usize, edge: @Vector(N, T)) void {
            std.debug.assert(i < N);
            self.base_edges[i] = edge;
            self.points[i] = self.base_point + edge;
        }

        pub fn center(self: Self) @Vector(N, T) {
            var c = vector.zero(N, T);
            for (self.points) |p| {
                c += p;
            }
            return vector.divided(c, @floatFromInt(N));
        }

        pub fn baseFaceCenter(self: Self, face_id: usize) @Vector(N, T) {
            var c = vector.zero(N, T);
            for (0..face_id) |i|
                c += self.points[i];
            for (face_id + 1..N) |i|
                c += self.points[i];
            c += self.base_point;
            return vector.divided(c, N);
        }

        pub fn translate(self: *Self, t: @Vector(N, T)) void {
            self.base_point += t;
            for (&self.points) |*p| {
                p.* += t;
            }
        }

        pub fn distanceToOrigin(self: Self) T {
            return vector.dot(self.normal(), -self.center());
        }

        //face with face_id is the face opposite to points[face_id]
        //that is which contains all points but points[face_id]
        //poniting towards the origin
        pub fn baseFaceNormal(self: Self, face_id: usize) @Vector(N, T) {
            std.debug.assert(face_id < N);
            var orthonormal: [N]@Vector(N, T) = undefined;
            @memcpy(orthonormal[0..face_id], self.base_edges[0..face_id]);
            @memcpy(orthonormal[face_id .. N - 1], self.base_edges[face_id + 1 .. N]);
            orthonormal[N - 1] = -self.base_point;
            ortho.gram_schmidt.orthonormalize(N, T, &orthonormal);
            return orthonormal[N - 1];
        }

        //pointing towards the origin
        pub fn normal(self: Self) @Vector(N, T) {
            var orthonormal: [N]@Vector(N, T) = undefined;
            for (1..N) |i| {
                orthonormal[i - 1] = self.points[i] - self.points[i - 1];
            }
            orthonormal[N - 1] = -self.points[0];
            ortho.gram_schmidt.orthonormalize(N, T, &orthonormal);
            return orthonormal[N - 1];
        }

        //works only if the new_point is in the region of space
        //delimited by the extensions of base_edges
        //into infinite rays with begginigs at base_point
        pub fn refine(self: *Self, new_point: @Vector(N, T)) void {
            const new_edge = new_point - self.base_point;
            var i: usize = 0;
            var j: usize = N - 1;
            var orthonormal: [N]@Vector(N, T) = undefined;
            orthonormal[0] = new_edge;
            for (0..N - 1) |_| {
                @memcpy(orthonormal[1 .. 1 + i], self.base_edges[0 .. 0 + i]);
                @memcpy(orthonormal[1 + i .. j], self.base_edges[i + 1 .. j]);
                @memcpy(orthonormal[j .. N - 1], self.base_edges[j + 1 .. N]);
                orthonormal[N - 1] = self.base_edges[i];
                ortho.gram_schmidt.orthonormalize(N, T, &orthonormal);
                const choice_normal = orthonormal[N - 1];
                if (vector.dot(choice_normal, -new_point) > 0) {
                    i += 1;
                } else {
                    j -= 1;
                }
            }
            self.points[i] = new_point;
            self.base_edges[i] = new_edge;
        }

        //should only be used in tests and assertions
        pub fn intersectsORay(self: Self) bool {
            for (0..N) |i| {
                const n = self.baseFaceNormal(i);
                if (vector.dot(n, self.base_edges[i]) < 0)
                    return false;
            }
            return true;
        }

        //should only be used in tests and assertions
        pub fn containsOrigin(self: Self) bool {
            return self.intersectsORay() and (vector.dot(self.normal(), self.base_point - self.center()) >= 0);
        }
    };
}

test "baseFaceNormal" {
    if (true) return error.SkipZigTest;
    const N = 10;
    const T = f32;
    for (0..100000) |_| {
        var portal = random.portal(N, T, tests.RAND);
        for (0..N) |i| {
            const normal = portal.baseFaceNormal(i);
            try std.testing.expect(
                vector.dot(normal, -portal.base_point) >= 0,
            );
            for (0..N) |j| {
                if (i != j)
                    try std.testing.expect(
                        vector.dot(normal, -portal.points[j]) >= 0,
                    );
            }
        }
    }
}

test "normal" {
    if (true) return error.SkipZigTest;
    const N = 10;
    const T = f32;
    for (0..100000) |_| {
        var portal = random.portal(N, T, tests.RAND);
        const normal = portal.normal();
        for (0..N) |j| {
            try std.testing.expect(
                vector.dot(normal, -portal.points[j]) >= 0,
            );
        }
    }
}

test "containsOrigin" {
    if (true) return error.SkipZigTest;
    const N = 10;
    const T = f32;
    for (0..100000) |_| {
        var portal = random.containingOrigin(N, T, tests.RAND);
        try std.testing.expect(portal.containsOrigin());
    }
}

test "intersectsORay" {
    if (true) return error.SkipZigTest;
    const N = 10;
    const T = f32;
    for (0..100000) |_| {
        var portal = random.intersectingORay(N, T, tests.RAND);
        try std.testing.expect(portal.intersectsORay());
    }
}

test "intersectingNotContaining" {
    if (true) return error.SkipZigTest;
    const N = 10;
    const T = f32;
    for (0..100000) |_| {
        var portal = random.intersectingNotContaining(N, T, tests.RAND);
        try std.testing.expect(portal.intersectsORay());
        try std.testing.expect(!portal.containsOrigin());
    }
}

test "refine" {
    if (true) return error.SkipZigTest;
    const N = 10;
    const T = f32;
    for (0..100000) |_| {
        var portal = random.intersectingNotContaining(N, T, tests.RAND);
        portal.refine(random.refinePoint(N, T, portal, tests.RAND));
        try std.testing.expect(portal.intersectsORay());
    }
}
