const std = @import("std");
const versions =
[_][]const u8
{
    "v1x11",
    "v1xcb",
    "v1wayland",
    "v1carboncocoa",
    "v1windows",
};
pub fn build(b: *std.Build) !void
{
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const dvui_dep = b.dependency("dvui", .{ .target = target, .optimize = optimize });
    const network_dep = b.dependency("network", .{ .target = target, .optimize = optimize });
    inline for (versions) |ver| {
        const exe = b.addExecutable(
        .{
            .target = target,
            .optimize = optimize,
            .name = ver ++ " Keybinder",
            .root_source_file = b.path("builds/" ++ ver ++ "/src/main.zig"),
        });
        exe.root_module.addImport("dvui", dvui_dep.module("dvui"));
        exe.root_module.addImport("sdl", dvui_dep.module("SDLBackend"));
        exe.root_module.addImport("network", network_dep.module("network"));
        if(std.mem.eql(u8, ver, "v1x11")) exe.addCSourceFile(.{ .file = b.path("X11/lib/Xlib.h") });
        const compile_step = b.step("compile-" ++ ver, "Compile " ++ ver);
        compile_step.dependOn(&b.addInstallArtifact(exe, .{}).step);
        b.getInstallStep().dependOn(compile_step);
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(compile_step);
        const run_step = b.step(ver, "Run " ++ ver);
        run_step.dependOn(&run_cmd.step);
    }
}
