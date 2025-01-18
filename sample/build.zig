const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Dependencies
    const vk_registry = b.dependency("vulkan_headers", .{}).path("registry/vk.xml").getPath(b);
    const vk_dep = b.dependency("vulkan_zig", .{ .registry = vk_registry });
    const vk_zig = vk_dep.module("vulkan-zig");

    const glfw_dep = b.dependency("mach-glfw", .{ .target = target, .optimize = optimize });
    const mach_glfw = glfw_dep.module("mach-glfw");

    const vma_dep = b.dependency("vk-mem-alloc-zig", .{ .target = target, .optimize = optimize });
    const vma_zig = vma_dep.module("vk-mem-alloc-zig");
    vma_zig.addImport("vulkan", vk_zig);

    // Executable
    const exe = b.addExecutable(.{
        .name = "sample",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("vulkan", vk_zig);
    exe.root_module.addImport("mach-glfw", mach_glfw);
    exe.root_module.addImport("vk-mem-alloc-zig", vma_zig);

    b.installArtifact(exe);

    // Run step for executable
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Compile check for ZLS
    const check = b.step("check", "Run compilation check");
    check.dependOn(&exe.step);
}
