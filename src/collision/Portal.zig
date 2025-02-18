const std = @import("std");
const tests = @import("tests");
const math = @import("math");
const vector = math.vector;
const ortho = math.ortho;
const approx = math.approx;

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
            self.base_edges[i] = vector.normalizedOrZero(point - self.base_point);
        }

        //face with face_id is the face opposite to points[face_id]
        //that is which contains all points but points[face_id]
        //pointing towards the point, so inside the simplex created
        //by the portal points and base_point
        pub fn baseFaceNormal(self: Self, face_id: usize) @Vector(N, T) {
            std.debug.assert(face_id < N);
            var orthonormal: [N]@Vector(N, T) = undefined;
            @memcpy(orthonormal[0..face_id], self.base_edges[0..face_id]);
            @memcpy(orthonormal[face_id .. N - 1], self.base_edges[face_id + 1 .. N]);
            orthonormal[N - 1] = self.base_edges[face_id];
            ortho.gramSchmidt(N, T, &orthonormal);
            return orthonormal[N - 1];
        }

        //pointing towards the base_point
        pub fn normal(self: Self) @Vector(N, T) {
            var orthonormal: [N]@Vector(N, T) = undefined;
            for (1..N) |i| {
                orthonormal[i - 1] = self.points[i] - self.points[i - 1];
            }
            orthonormal[N - 1] = -self.base_edges[0];
            ortho.gramSchmidt(N, T, &orthonormal);
            return orthonormal[N - 1];
        }

        //works only if the new_point is in the region of space
        //delimited by the extensions of base_edges
        //into infinite rays with begginigs at base_point
        pub fn refine(self: *Self, new_point: @Vector(N, T)) void {
            const new_edge = new_point - self.base_point;
            var i: usize = 0;
            var j: usize = N - 1;
            var orthonormal: [N - 1]@Vector(N, T) = undefined;
            orthonormal[0] = vector.normalizedOrZero(new_edge);
            for (0..N - 1) |_| {
                @memcpy(orthonormal[1 .. 1 + i], self.base_edges[0 .. 0 + i]);
                @memcpy(orthonormal[1 + i .. j], self.base_edges[i + 1 .. j]);
                @memcpy(orthonormal[j .. N - 1], self.base_edges[j + 1 .. N]);
                ortho.gramSchmidt(N, T, &orthonormal);
                const choice_normal = ortho.gramSchmidtOne(N, T, &orthonormal, self.base_edges[i]);
                if (vector.dot(choice_normal, -new_point) >= 0) {
                    i += 1;
                } else {
                    j -= 1;
                }
            }
            self.points[i] = new_point;
            self.base_edges[i] = new_edge;
        }

        //should be used only in tests and assertions
        pub fn originRayIntersects(self: Self) bool {
            for (0..N) |i| {
                const n = self.baseFaceNormal(i);
                if (vector.dot(n, -self.base_point) < 0)
                    return false;
            }
            return true;
        }

        //should be used only in tests and assertions
        pub fn containsOrigin(self: Self) bool {
            return self.originRayIntersects() and (vector.dot(self.normal(), -self.points[0]) >= 0);
        }

        pub fn isDegenerate(self: Self) bool {
            var orhonormal: [N]@Vector(N, T) = self.base_edges;
            ortho.gramSchmidt(N, T, &orhonormal);
            std.debug.print("{d}\n", .{orhonormal[N - 1]});
            return vector.approxZeroAbs(orhonormal[N - 1]);
        }
    };
}

fn randomPortal(N: comptime_int, T: type, rand: std.Random) Portal(N, T) {
    var portal = Portal(N, T).new(vector.randomRange(N, T, rand, -1, 1));
    for (0..N) |i| {
        portal.setPoint(i, vector.randomRange(N, T, rand, -1, 1));
    }
    return portal;
}

fn randomPortalDegenerate(N: comptime_int, T: type, rand: std.Random) Portal(N, T) {
    var rand_points: [N]@Vector(N, T) = undefined;
    for (0..N) |i| {
        rand_points[i] = vector.randomRange(N, T, rand, -1, 1);
    }
    var next_point = rand_points[0];
    for (1..N) |i| {
        next_point += vector.scaled(rand_points[i] - rand_points[0], rand.float(T));
    }
    var portal = Portal(N, T).new(next_point);
    for (0..N) |i| {
        portal.setPoint(
            i,
            rand_points[i],
        );
    }
    return portal;
}

fn randomPortalContainingOrigin(N: comptime_int, T: type, rand: std.Random) Portal(N, T) {
    var rand_points: [N]@Vector(N, T) = undefined;
    for (0..N) |i| {
        rand_points[i] = vector.randomRange(N, T, rand, -1, 1);
    }
    var next_point = vector.zero(N, T);
    for (0..N) |i| {
        next_point += vector.scaled(rand_points[i], -rand.float(T));
    }
    var portal = Portal(N, T).new(next_point);
    for (0..N) |i| {
        portal.setPoint(i, rand_points[i]);
    }
    return portal;
}

//fn randomPortalIntersectingOriginRay(N: comptime_int, T: type, rand: std.Random) Portal(N, T) {

test "baseFaceNormal" {
    const N = 10;
    const T = f32;
    for (0..1000) |_| {
        var portal = randomPortal(N, T, tests.RAND);
        for (0..N) |i| {
            const normal = portal.baseFaceNormal(i);
            try std.testing.expect(
                vector.dot(normal, portal.base_edges[i]) > 0,
            );
            for (0..N) |j| {
                if (i != j)
                    try std.testing.expect(
                        vector.dot(normal, portal.points[i] - portal.points[j]) > 0,
                    );
            }
        }
    }
}

test "normal" {
    const N = 10;
    const T = f32;
    for (0..1000) |_| {
        var portal = randomPortal(N, T, tests.RAND);
        const normal = portal.normal();
        for (0..N) |j| {
            try std.testing.expect(
                vector.dot(normal, -portal.base_edges[j]) > 0,
            );
        }
    }
}

test "isDegenerate" {
    const N = 2;
    const T = f32;
    for (0..1000) |_| {
        var portal = randomPortalDegenerate(N, T, tests.RAND);
        if (!portal.isDegenerate())
            std.debug.print("WRONG {d}, {d}\n", .{ portal.base_edges, portal.base_point });
        // try std.testing.expect(portal.isDegenerate());
    }
}

test "containsOrigin" {
    const N = 10;
    const T = f32;
    for (0..1000) |_| {
        var portal = randomPortalContainingOrigin(N, T, tests.RAND);
        try std.testing.expect(portal.containsOrigin());
    }
}

test "refine" {
    const N = 2;
    const T = f32;
    for (0..1000) |_| {
        var portal = randomPortalContainingOrigin(N, T, tests.RAND);
        var center = vector.zero(N, T);
        for (0..N) |i| {
            center += portal.points[i];
        }
        center = vector.divided(center, @floatFromInt(N));
        for (0..N) |i| {
            center += vector.scaled(portal.base_edges[i], tests.RAND.float(T));
        }
        portal.refine(center);
        // if (!portal.originRayIntersects())
        // std.debug.print("portal: {d}, {d}\n", .{ portal.points, portal.base_point });
        try std.testing.expect(portal.originRayIntersects());
    }
}
