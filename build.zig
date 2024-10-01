const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const dvui_dep = b.dependency("dvui", .{
        .target = target,
        .optimize = optimize
    });
    const network_dep = b.dependency("network", .{
        .target = target,
        .optimize = optimize
    });
    const exe = b.addExecutable(.{
        .target = target,
        .optimize = optimize,
        .name = "Keybinder's Keybinder",
        .root_source_file = b.path("src/main.zig"),
    });
    exe.root_module.addImport("dvui", dvui_dep.module("dvui"));
    exe.root_module.addImport("sdl", dvui_dep.module("SDLBackend"));
    exe.root_module.addImport("network", network_dep.module("network"));
    exe.addCSourceFile(.{
        .file = b.path("X11/Xlib.h"),
    });
    exe.addIncludePath(b.path("X11/"));
    b.installArtifact(exe);
}
