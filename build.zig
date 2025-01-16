const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const vma_dep = b.dependency("vma", .{});
    const vma_include_path = vma_dep.path("include");
    const vma = b.addStaticLibrary(.{
        .name = "vma",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    vma.linkLibCpp();

    vma.addCSourceFile(.{ .file = b.path("src/vma.cc"), .flags = &.{"-std=c++17"} });
    vma.addIncludePath(vma_include_path);

    var module = b.addModule("vk-mem-alloc-zig", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    });

    module.linkLibrary(vma);
    module.addIncludePath(vma_include_path);
}
