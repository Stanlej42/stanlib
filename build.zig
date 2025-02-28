const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    const lib = b.addStaticLibrary(.{
        .name = "stanlib",
        .root_source_file = b.path("src/stanlib.zig"),
        .target = target,
        .optimize = std.builtin.OptimizeMode.ReleaseFast,
    });
    lib.root_module.addImport("stanlib", &lib.root_module);

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    // const tests_mod = b.createModule(.{
    //     .root_source_file = b.path("src/tests.zig"),
    //     .target = target,
    //     .optimize = std.builtin.OptimizeMode.Debug,
    // });

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const tests_module = b.createModule(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
        .optimize = std.builtin.OptimizeMode.Debug,
    });
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/stanlib.zig"),
        .target = target,
        .optimize = std.builtin.OptimizeMode.Debug,
    });
    unit_tests.root_module.addImport("stanlib", &unit_tests.root_module);
    unit_tests.root_module.addImport("tests", tests_module);

    const run_unit_tests = b.addRunArtifact(unit_tests);
    run_unit_tests.has_side_effects = true; //prevents caching
    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
