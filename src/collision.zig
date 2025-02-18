const std = @import("std");
const tests = @import("tests");
const math = @import("math");
const vector = math.vector;
const ortho = math.ortho;
pub const aabb = @import("collision/AABB.zig");
pub const ball = @import("collision/Ball.zig");
pub const portal = @import("collision/Portal.zig");
pub const mpr = @import("collision/mpr.zig");

// pub fn minkDiff(N: comptime_int, T: type, A: anytype, B: anytype, dir: @Vector(N, T)) @Vector(N, T) {
//     return A.support(dir) - B.support(-dir);
// }

// pub fn MPR(N: comptime_int, T: type, A: anytype, B: anytype) bool {
//     //find origin ray
//     var portal = Portal(N, T).new();
//     portal.setBasePoint(A.interior() - B.interior());

//     //find candidate portal
//     var orthonormal: [N - 1]@Vector(N, T) = undefined;
//     var search_dir: @Vector(N, T) = undefined;
//     for (0..N - 1) |i| {
//         search_dir = ortho.gramSchmidtOne(
//             N,
//             T,
//             orthonormal[0..i],
//             -portal.lastPoint(),
//         );
//         // std.debug.print("search_dir: {d}\n", .{search_dir});
//         if (vector.approxZero(search_dir)) {
//             const normal = portal.normal();
//             // std.debug.print("AAAAAAA\n", .{});
//             // std.debug.print("Normal: {d}\n", .{normal});
//             return vector.dot(normal, -portal.lastPoint()) >= 0;
//         }
//         portal.setPoint(minkDiff(N, T, A, B, search_dir));
//         // if (vector.dot(search_dir, -portal.lastPoint()) > 0)
//         //     return false;
//         orthonormal[i] = ortho.gramSchmidtOne(
//             N,
//             T,
//             orthonormal[0..i],
//             portal.lastBaseEdge(),
//         );
//     }
//     search_dir = ortho.gramSchmidtOne(
//         N,
//         T,
//         orthonormal[0 .. N - 1],
//         -portal.lastPoint(),
//     );
//     if (vector.approxZero(search_dir)) {
//         const normal = portal.normal();
//         // std.debug.print("AAAAAAA\n", .{});
//         // std.debug.print("Normal: {d}\n", .{normal});
//         return vector.dot(normal, -portal.lastPoint()) >= 0;
//     }
//     portal.setPoint(minkDiff(N, T, A, B, search_dir));
//     // if (vector.dot(search_dir, -portal.lastPoint()) > 0)
//     //     return false;

//     //check if intersects ray, otherwise choose new candidate
//     var rayPasses = false;
//     while (!rayPasses) {
//         rayPasses = true;
//         for (0..N - 1) |i| {
//             const normal = portal.baseFaceNormal(i);
//             if (vector.dot(normal, -portal.base_point) < 0) {
//                 portal.replacePoint(i, minkDiff(N, T, A, B, -normal));
//                 rayPasses = false;
//                 break;
//             }
//         }
//     }

//     // std.debug.print("REFINE\n", .{});
//     //refine portal
//     // std.debug.print("points: {d}\n", .{portal.points});
//     for (0..10) |_| {
//         // while (true) {
//         const normal = portal.normal();
//         // std.debug.print("Normal: {}\n", .{normal});
//         const d1 = vector.dot(normal, -portal.lastPoint());
//         // std.debug.print("d: {}\n", .{d1});
//         // if (vector.approxZero(normal)) {
//         //     return true;
//         // }
//         if (d1 >= 0) {
//             // std.debug.print("Normal: {d}\n", .{normal});
//             // std.debug.print("Points: {d}\n", .{portal.points});
//             // std.debug.print("Edges: {d}\n", .{portal.base_edges});
//             // std.debug.print("Base: {d}\n", .{portal.base_point});
//             return true;
//         }
//         const new_point = minkDiff(N, T, A, B, -normal);
//         // std.debug.print("New point: {d}\n", .{new_point});
//         const d2 = vector.dot(normal, -new_point);
//         if (d2 <= 0)
//             return false;

//         // const d = d2 - d1;
//         // std.debug.print("d: {}\n", .{d2});
//         portal.refine(new_point);
//     }
//     // std.debug.print("Points: {d}\n", .{portal.points});
//     // std.debug.print("Edges: {d}\n", .{portal.base_edges});
//     // std.debug.print("Base: {d}\n", .{portal.base_point});
//     return false;
// }

// fn randomAABBs(N: comptime_int, T: type, rand: std.Random) [2]AABB(N, T) {
//     const v1 = vector.randomRange(N, T, rand, -1, 1);
//     const v2 = vector.randomRange(N, T, rand, -1, 1);
//     const v3 = vector.randomRange(N, T, rand, -1, 1);
//     const v4 = vector.randomRange(N, T, rand, -1, 1);
//     var aabbs = [2]AABB(N, T){
//         AABB(N, T).new(@min(v1, v2), @max(v1, v2)),
//         AABB(N, T).new(@min(v3, v4), @max(v3, v4)),
//     };
//     if (rand.float(T) < 0.5) {
//         //make intersect
//         const min1 = @min(aabbs[0].bottom_left, aabbs[1].top_right);
//         const max2 = @max(aabbs[0].bottom_left, aabbs[1].top_right);
//         const min2 = @min(aabbs[1].bottom_left, aabbs[0].top_right);
//         const max1 = @max(aabbs[1].bottom_left, aabbs[0].top_right);
//         aabbs[0] = AABB(N, T).new(min1, max1);
//         aabbs[1] = AABB(N, T).new(min2, max2);
//     } else {
//         //make not intersect
//         const i: usize = rand.intRangeLessThan(usize, 0, N);
//         var j: usize = 0;
//         var k: usize = 0;
//         if (rand.float(T) < 0.5) {
//             j = 1;
//         } else {
//             k = 1;
//         }
//         var values = [4]T{
//             aabbs[0].bottom_left[i],
//             aabbs[0].top_right[i],
//             aabbs[1].bottom_left[i],
//             aabbs[1].top_right[i],
//         };
//         std.mem.sort(T, &values, {}, std.sort.asc(T));
//         aabbs[j].bottom_left[i] = values[0];
//         aabbs[j].top_right[i] = values[1];
//         aabbs[k].bottom_left[i] = values[2];
//         aabbs[k].top_right[i] = values[3];
//     }
//     std.debug.assert(aabbs[0].isCorrect() and aabbs[1].isCorrect());
//     return aabbs;
// }

// fn randomBalls(N: comptime_int, T: type, rand: std.Random) [2]Ball(N, T) {
//     const v1 = vector.randomRange(N, T, rand, -0.5, 0.5);
//     const v2 = vector.randomRange(N, T, rand, -0.5, 0.5);
//     const d = vector.length(v2 - v1);
//     var balls: [2]Ball(N, T) = undefined;
//     var r1: T = undefined;
//     var r2: T = undefined;

//     if (rand.float(T) < 0.5) {
//         //make intersecting
//         r1 = rand.float(T);
//         const b = @max(d - r1, 0);
//         r2 = b + 1 * rand.float(T);
//     } else {
//         //make non-intersecting
//         r1 = d * rand.float(T);
//         r2 = (d - r1) * rand.float(T);
//     }

//     balls[0] = Ball(N, T).new(v1, r1);
//     balls[1] = Ball(N, T).new(v2, r2);

//     return balls;
// }

// fn BallAABBintersect(
//     ball: anytype,
//     aabb: anytype,
// ) bool {
//     const nearest = std.math.clamp(
//         ball.pos,
//         aabb.bottom_left,
//         aabb.top_right,
//     );
//     return ball.contains(nearest);
// }

// fn randomShapes(N: comptime_int, T: type, rand: std.Random) struct { AABB(N, T), Ball(N, T) } {
//     var aabb: AABB(N, T) = undefined;
//     var ball: Ball(N, T) = undefined;

//     const v1 = vector.randomRange(N, T, rand, -1, 1);
//     const v2 = vector.randomRange(N, T, rand, -1, 1);
//     aabb = AABB(N, T).new(@min(v1, v2), @max(v1, v2));
//     var p = vector.randomRange(N, T, rand, -1, 1);
//     if (rand.float(T) < 0.5) {
//         //make intersecting
//         const nearest = std.math.clamp(
//             p,
//             aabb.bottom_left,
//             aabb.top_right,
//         );
//         const dist = vector.length(nearest - p);
//         const r = dist + rand.float(T);
//         ball = Ball(N, T).new(p, r);
//     } else {
//         //make non-intersecting
//         const i: usize = rand.intRangeLessThan(usize, 0, N);
//         var values = [3]T{ aabb.bottom_left[i], aabb.top_right[i], p[i] };
//         std.mem.sort(T, &values, {}, std.sort.asc(T));
//         if (rand.float(T) < 0.5) {
//             p[i] = values[0];
//             aabb.bottom_left[i] = values[1];
//             aabb.top_right[i] = values[2];
//         } else {
//             aabb.bottom_left[i] = values[0];
//             aabb.top_right[i] = values[1];
//             p[i] = values[2];
//         }
//         const nearest = std.math.clamp(
//             p,
//             aabb.bottom_left,
//             aabb.top_right,
//         );
//         const dist = vector.length(nearest - p);
//         const r = dist * rand.float(T);
//         ball = Ball(N, T).new(p, r);
//     }

//     return .{ aabb, ball };
// }

// test "random AABBs" {
//     const testN = 1;
//     var correctN: usize = 0;
//     var intersectingN: usize = 0;
//     const N = 4;
//     const T = f32;
//     for (0..testN) |_| {
//         // while (true) {
//         const aabbs = randomAABBs(N, T, tests.RAND);
//         const expected = aabbs[0].intersects(aabbs[1]);
//         if (expected)
//             intersectingN += 1;
//         const actual = MPR(N, T, aabbs[0], aabbs[1]);
//         if (expected == actual) {
//             correctN += 1;
//         } else {
//             // std.debug.print("\nWRONG\n\n", .{});
//             // std.debug.print("shape1: {d},{d}\n", .{ aabbs[0].bottom_left, aabbs[0].top_right });
//             // std.debug.print("shape2: {d},{d}\n", .{ aabbs[1].bottom_left, aabbs[1].top_right });
//             std.debug.print("expected: {}\n", .{expected});
//             // break;
//         }
//         // try std.testing.expectEqual(expected, actual);
//     }
//     std.debug.print("Correct AABBs: {}/{}, {d:.1}%\n", .{ correctN, testN, (@as(f32, @floatFromInt(correctN)) / @as(f32, @floatFromInt(testN)) * 100.0) });
//     std.debug.print("Intersecting: {} Non-intersecting: {}\n", .{ intersectingN, testN - intersectingN });
// }

// test "random Balls" {
//     const testN = 1;
//     var correctN: usize = 0;
//     var intersectingN: usize = 0;
//     const N = 10;
//     const T = f64;
//     for (0..testN) |_| {
//         // while (true) {
//         const balls = randomBalls(N, T, tests.RAND);
//         const expected = balls[0].intersects(balls[1]);
//         if (expected)
//             intersectingN += 1;
//         const actual = MPR(N, T, balls[0], balls[1]);
//         if (expected == actual) {
//             correctN += 1;
//         } else {
//             std.debug.print("\nWRONG\n\n", .{});
//             std.debug.print("shape1: {d},{d}\n", .{ balls[0].pos, balls[0].radius });
//             std.debug.print("shape2: {d},{d}\n", .{ balls[1].pos, balls[1].radius });
//             std.debug.print("expected: {}\n", .{expected});
//             // break;
//         }
//         // try std.testing.expectEqual(expected, actual);
//     }
//     std.debug.print("Correct Balls: {}/{}, {d:.1}%\n", .{ correctN, testN, (@as(f32, @floatFromInt(correctN)) / @as(f32, @floatFromInt(testN)) * 100.0) });
//     std.debug.print("Intersecting: {} Non-intersecting: {}\n", .{ intersectingN, testN - intersectingN });
// }

// test "random shapes" {
//     const testN = 1;
//     var correctN: usize = 0;
//     var intersectingN: usize = 0;
//     const N = 4;
//     const T = f64;
//     for (0..testN) |_| {
//         // while (true) {
//         const aabb, const ball = randomShapes(N, T, tests.RAND);
//         const expected = BallAABBintersect(ball, aabb);
//         if (expected)
//             intersectingN += 1;
//         const actual = MPR(N, T, aabb, ball);
//         if (expected == actual) {
//             correctN += 1;
//         } else {
//             std.debug.print("\nWRONG\n\n", .{});
//             std.debug.print("aabb: {d},{d}\n", .{ aabb.bottom_left, aabb.top_right });
//             std.debug.print("ball: {d},{d}\n", .{ ball.pos, ball.radius });
//             std.debug.print("expected: {}\n", .{expected});
//             // break;
//         }
//         // try std.testing.expectEqual(expected, actual);
//     }
//     std.debug.print("Correct shapes: {}/{}, {d:.1}%\n", .{ correctN, testN, (@as(f32, @floatFromInt(correctN)) / @as(f32, @floatFromInt(testN)) * 100.0) });
//     std.debug.print("Intersecting: {} Non-intersecting: {}\n", .{ intersectingN, testN - intersectingN });
// }
