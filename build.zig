const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dep = b.dependency("vma", .{});
    const include_path = dep.path("include");
    const lib = b.addStaticLibrary(.{
        .name = "vma",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib.linkLibCpp();

    // Generate implementation
    const impl = try std.fs.createFileAbsolute(
        try dep.path("vma.cc").getPath3(b, &lib.step).toString(b.allocator),
        .{},
    );
    try impl.writeAll(
        \\#define VMA_IMPLEMENTATION
        \\#define VMA_STATIC_VULKAN_FUNCTIONS 0
        \\#include <vk_mem_alloc.h>
    );
    impl.close();

    lib.addCSourceFile(.{ .file = dep.path("vma.cc"), .flags = &.{"-std=c++17"} });
    lib.addIncludePath(include_path);

    var module = b.addModule("vk-mem-alloc-zig", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    });

    module.linkLibrary(lib);
}
