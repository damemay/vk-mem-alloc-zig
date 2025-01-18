# vk-mem-alloc-zig
This module packs and wraps [VulkanMemoryAllocator (3.2.0)](https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator) for easy zig-like usage with [vulkan-zig (master)](https://github.com/Snektron/vulkan-zig).

The only dependency in `build.zig.zon` is VMA repo fetched for the header file. vulkan-zig module should be compiled by user and added into this module (see **Usage** below).

**Many functions are largely untested** because I only use a few of them. Pull requests are welcome if anyone finds issues in any behaviour or usage.

## TODO:
- Create structs that wrap VMA functions as methods.

## Usage

```bash
zig fetch --save https://github.com/damemay/vk-mem-alloc-zig/archive/COMMIT.tar.gz
```

```zig
// build.zig:
// ...
const vma_dep = b.dependency("vk-mem-alloc-zig", .{
    .target = target,
    .optimize = optimize,
});
const vma_zig = vma_dep.module("vk-mem-alloc-zig");
// Add vulkan-zig import to vk-mem-alloc-zig!
vma_zig.addImport("vulkan", vk_zig);
// ...
exe.root_module.addImport("vk-mem-alloc-zig", vma_zig);
```
