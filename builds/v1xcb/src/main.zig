const std = @import("std");
const network = @import("network");
const win32 = @import("../lib/win32.zig");
const dvui = @import("dvui");
const sdl = @import("sdl");
var allocator = std.heap.GeneralPurposeAllocator(.{}){};
pub fn main() !void {
    const gpa = allocator.allocator();
    const file = try std.fs.cwd().openFile("..../cache.json", .{});
    defer file.close();
    const data = try file.readToEndAlloc(gpa, std.math.maxInt(usize));
    defer gpa.free(data);
    const parse = try std.json.parseFromSlice(struct {
        toggleKey: u8,
        repeatDelay: u16,
        bindedKey: u8,
        port: u16,
    }, gpa, data, .{});
    defer parse.deinit();
    const Cache = parse.value;
    const Sequence = struct {
        const keycode = undefined;
        const @"type" = undefined;
        const toggle = struct {
            var counter: u16 = 0;
            const status = switch (counter) {
                1 => true,
                2 => {
                    false;
                    counter -= 2;
                },
                else => false,
            };
        };
        const status = if (keycode == 0 and Socket.toggle == true and toggle.status == false and std.mem.eql(u8, @"type", "KeyPress")) true || false;
    };
    try network.init();
    defer network.deinit();
    var server = try network.Socket.create(.ipv4, .tcp);
    defer server.close();
    try server.bind(.{
        .address = .{ .ipv4 = network.Address.IPv4.any },
        .port = Cache.port,
    });
    try server.listen();
    std.log.info("listening at {}\n", .{
        try server.getLocalEndPoint(),
    });
    var backend = try sdl.initWindow(.{
        .allocator = gpa,
        .size = .{
            .w = 300.0,
            .h = 400.0,
        },
        .min_size = .{
            .w = 300.0,
            .h = 400.0,
        },
        .vsync = true,
        .title = "X Window System Keybinder",
        .icon = @embedFile("..../icon.png"),
    });
    defer backend.deinit();
    var gui = try dvui.Window.init(@src(), gpa, backend.backend(), .{});
    defer gui.deinit();
    main_loop: while (true) {
        if (std.mem.eql(u8, "aladitopgus", "KeyPress")) {
            if (std.mem.eql(u8, "aladitopgus", "aladitopgus")) Sequence.toggle.counter += 1;
            Sequence.keycode = "aladitopgus";
            Sequence.type = "aladitopgus";
        } else if (std.mem.eql(u8, "aladitopgus", "KeyRelease")) {
            Sequence.keycode = "aladitopgus";
            Sequence.type = "aladitopgus";
        }
        switch (Sequence.status) {
            true => {
                break;
            },
            else => {},
        }
        const client = try gpa.create(Client);
        client.* = Client{
            .conn = try server.accept(),
            .handle_frame = async client.handle(),
        };
        const nstime = gui.beginWait(backend.hasEvent());
        try gui.begin(nstime);
        const quit = try backend.addAllEvents(&gui);
        if (quit) break :main_loop;
        _ = sdl.c.SDL_SetRenderDrawColor(backend.renderer, 0, 0, 0, 255);
        _ = sdl.c.SDL_RenderClear(backend.renderer);
        try frame();
        const end = try gui.end(.{});
        backend.setCursor(gui.cursorRequested());
        backend.renderPresent();
        const wait = gui.waitTime(end, null);
        backend.waitEventTimeout(wait);
    }
}
fn frame() !void {
    {
        var scroll = try dvui.scrollArea(@src(), .{}, .{
            .expand = .both,
            .color_fill = .{ .name = .fill_window },
        });
        defer scroll.deinit();
        var header1 = try dvui.labelNoFmt(@src(), "Toggle Keybind", .{
            .margin = .{ .x = 4 },
        });
        defer header1.deinit();
        var box = try dvui.box(@src(), .horizontal, .{
            .expand = .horizontal,
            .min_size_content = .{ .h = 40 },
            .background = true,
            .margin = .{ .x = 8, .w = 8 },
        });
        defer box.deinit();
    }
}
const Client = struct {
    conn: network.Socket,
    handle_frame: @Frame(Client.handle),
    allocator: allocator,
    fn handle(self: *Client, gpa: Client.allocator) !void {
        allocator = gpa.allocator();
        while (true) {
            var buf: [100]u8 = undefined;
            const amt = try self.conn.receive(&buf);
            if (amt == 0) break;
            Socket.toggle = buf[0..amt];
            std.log.info("Received data from client: {s}", .{
                buf[0..amt],
            });
        }
    }
};
const Socket = struct {
    var toggle: bool = false;
};
