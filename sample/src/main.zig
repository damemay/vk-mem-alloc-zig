const std = @import("std");
const glfw = @import("mach-glfw");
const vk = @import("vulkan");
const vma = @import("vk-mem-alloc-zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer if (gpa.deinit() == .leak) @panic("leaked");

    if (!glfw.init(.{})) @panic("failed to init glfw");
    defer glfw.terminate();

    const window = glfw.Window.create(800, 600, "sample", null, null, .{
        .client_api = .no_api,
        .visible = false,
    }) orelse @panic("failed to create window");
    defer window.destroy();

    const apis: []const vk.ApiInfo = &.{vk.features.version_1_0};
    const BaseDispatch = vk.BaseWrapper(apis);
    const InstanceDispatch = vk.InstanceWrapper(apis);
    const DeviceDispatch = vk.DeviceWrapper(apis);
    const Instance = vk.InstanceProxy(apis);
    const Device = vk.DeviceProxy(apis);

    const base = try BaseDispatch.load(@as(
        vk.PfnGetInstanceProcAddr,
        @ptrCast(&glfw.getInstanceProcAddress),
    ));

    const glfw_extensions = glfw.getRequiredInstanceExtensions() orelse
        return glfw.getErrorCode();

    const tmp_instance = try base.createInstance(&.{
        .p_application_info = &.{
            .application_version = vk.makeApiVersion(0, 0, 0, 0),
            .engine_version = vk.makeApiVersion(0, 0, 0, 0),
            .api_version = vk.API_VERSION_1_0,
        },
        .enabled_extension_count = @intCast(glfw_extensions.len),
        .pp_enabled_extension_names = @ptrCast(glfw_extensions.ptr),
    }, null);

    const instance_wrapper = try allocator.create(InstanceDispatch);
    defer allocator.destroy(instance_wrapper);

    const instance = blk: {
        errdefer allocator.destroy(instance_wrapper);

        instance_wrapper.* = try InstanceDispatch.load(
            tmp_instance,
            base.dispatch.vkGetInstanceProcAddr,
        );
        break :blk Instance.init(tmp_instance, instance_wrapper);
    };
    defer instance.destroyInstance(null);

    const physical_device = blk: {
        const pdevs = try instance.enumeratePhysicalDevicesAlloc(allocator);
        defer allocator.free(pdevs);

        if (pdevs.len == 0) @panic("no vulkan gpu");

        break :blk pdevs[0];
    };

    const queue_index = blk: {
        const queue_props = try instance.getPhysicalDeviceQueueFamilyPropertiesAlloc(
            physical_device,
            allocator,
        );
        defer allocator.free(queue_props);

        for (queue_props, 0..) |props, i| {
            if (props.queue_flags.contains(.{ .graphics_bit = true })) {
                const index: u32 = @intCast(i);
                break :blk index;
            }
        }
        break :blk std.math.maxInt(u32);
    };
    if (queue_index == std.math.maxInt(u32)) @panic("no graphics queue");

    const queue_priority: f32 = 1.0;
    const queue_info = vk.DeviceQueueCreateInfo{
        .queue_family_index = queue_index,
        .queue_count = 1,
        .p_queue_priorities = @ptrCast(&queue_priority),
    };

    const tmp_device = try instance.createDevice(physical_device, &.{
        .queue_create_info_count = 1,
        .p_queue_create_infos = @ptrCast(&queue_info),
        .p_enabled_features = null,
    }, null);

    const device_wrapper = try allocator.create(DeviceDispatch);
    device_wrapper.* = try DeviceDispatch.load(
        tmp_device,
        instance.wrapper.dispatch.vkGetDeviceProcAddr,
    );
    defer allocator.destroy(device_wrapper);

    const device = Device.init(tmp_device, device_wrapper);
    defer device.destroyDevice(null);

    const vulkan_f = vma.VulkanFunctions{
        .vkGetInstanceProcAddr = base.dispatch.vkGetInstanceProcAddr,
        .vkGetDeviceProcAddr = instance.wrapper.dispatch.vkGetDeviceProcAddr,
    };
    const info = vma.AllocatorCreateInfo{
        .physical_device = physical_device,
        .device = device.handle,
        .p_vulkan_functions = @ptrCast(&vulkan_f),
        .instance = instance.handle,
        .vulkan_api_version = vk.API_VERSION_1_0,
    };

    var vma_allocator: vma.Allocator = undefined;
    if (vma.vmaCreateAllocator(&info, &vma_allocator) != .success)
        @panic("failed to init vma");
}
