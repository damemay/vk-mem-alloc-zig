# vk-mem-alloc-zig
vk_mem_alloc.h 3.2.0 for vulkan-zig


## Usage

```bash
zig fetch --save https://github.com/damemay/vk-mem-alloc-zig/archive/COMMIT.tar.gz
```

```zig
const vma_dep = b.dependency("vk-mem-alloc-zig", .{ .target = target, .optimize = optimize });
const vma_zig = vma_dep.module("vk-mem-alloc-zig");
vma_zig.addImport("vulkan", vk_zig);
// ...
exe.root_module.addImport("vk-mem-alloc-zig", vma_zig);
```
