const std = @import("std");
const tests = @import("tests");
const math = @import("stanlib").math;
const vector = math.vector;
const ortho = @import("stanlib").ortho;
const Portal = @import("Portal.zig").Portal;

pub fn minkDiff(N: comptime_int, T: type, A: anytype, B: anytype, dir: @Vector(N, T)) @Vector(N, T) {
    return A.support(dir) - B.support(-dir);
}

fn findCandidate(
    N: comptime_int,
    T: type,
    A: anytype,
    B: anytype,
    portal: *Portal(N, T),
) ?bool {
    var search_dir = -portal.base_point;
    var orthonormal: [N - 1]@Vector(N, T) = undefined;
    for (0..N - 1) |i| {
        if (vector.approxZeroAbs(search_dir)) return true;
        const new_point = minkDiff(N, T, A, B, search_dir);
        if (vector.dot(search_dir, -new_point) >= 0) return false;
        portal.setPoint(i, new_point);
        orthonormal[i] = ortho.gramSchmidtOne(
            N,
            T,
            orthonormal[0..i],
            portal.base_edges[i],
        );
        search_dir = ortho.gramSchmidtOne(
            N,
            T,
            orthonormal[0..i],
            -new_point,
        );
    }
    if (vector.approxZeroAbs(search_dir)) return true;
    const new_point = minkDiff(N, T, A, B, search_dir);
    if (vector.dot(search_dir, -new_point) >= 0) return false;
    portal.setPoint(N - 1, new_point);
    return null;
}

fn betterCandidate(
    N: comptime_int,
    T: type,
    A: anytype,
    B: anytype,
    portal: *Portal(N, T),
) ?bool {
    while (true) {
        for (0..N - 1) |i| {
            const normal = portal.baseFaceNormal(i);
            if (vector.dot(normal, -portal.base_point) < 0) {
                const search_dir = -normal;
                const new_point = minkDiff(N, T, A, B, search_dir);
                if (vector.dot(search_dir, -new_point) >= 0) return false;
                portal.points[i] = portal.points[N - 1];
                portal.base_edges[i] = portal.base_edges[N - 1];
                portal.setPoint(N - 1, new_point);
                break;
            }
        }
    }
    return null;
}
pub fn MPR(N: comptime_int, T: type, A: anytype, B: anytype) bool {
    const portal = Portal(N, T).new(A.interior() - B.interior());
    const candidate_exit = findCandidate(N, T, A, B, &portal);
    if (candidate_exit) return candidate_exit.?;
    const better_candidate_exit = betterCandidate(N, T, A, B, &portal);
    if (better_candidate_exit) return better_candidate_exit.?;
    //find better candidate

    return false;
}
