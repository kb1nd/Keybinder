const std = @import("std");
const network = @import("network");
const x11 = @cImport({
    @cInclude("Xlib.h");
});
const dvui = @import("dvui");
const sdl = @import("sdl");
const json = @import("json");

var allocator = std.heap.GeneralPurposeAllocator(.{}){};

const active = switch(Cache.payload) {
    1 => true,
    0 => false,
};

pub fn main() !void {
    const gpa = allocator.allocator();

    // Parse the cache
    const data = try std.fs.cwd().openFile("cache.json", .{});
    defer data.close();
    const cache = try json.parseFile(data, gpa);
    errdefer cache.deinit(gpa);
    defer cache.deinit(gpa);

    // Key repeat sequence varibles
    const display = x11.XOpenDisplay(null);
    const keycode = x11.XKeysymToKeycode(display, x11.XStringToKeysym(cache.bindedKey));
    const event = x11.XEvent;
    const window = x11.XDefaultRootWindow(display);
    const key_held = if(event.keycode == keycode and active == true) {
        if(std.mem.eql(u8, event.type, "KeyPress")) {
            true;
        } else if(std.mem.eql(u8, event.type, "KeyRelease")) {
            false;
        }
    } else {
        false;
    };

    // Create the socket server
    try network.init();
    defer network.deinit();

    var server = try network.Socket.create(.ipv4, .tcp);
    defer server.close();

    try server.bind(.{
        .address = .{
            .ipv4 = network.Address.IPv4.any
        },
        .port = cache.port,
    });

    try server.listen();
    std.log.info("listening at {}\n", .{
        try server.getLocalEndPoint()
    });
    while (true) {
        std.debug.print("Waiting for connection\n", .{});
        const client = try gpa.create(Client);
        client.* = Client{
            .conn = try server.accept(),
            .handle_frame = async client.handle(),
        };
    }

    // Init SDL backend (creates and owns OS window)
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
        .title = "Keybinder's Keybinder",
        .icon = @embedFile("appIcon.png"),
    });
    defer backend.deinit();

    // Init dvui Window (maps onto a single OS window)
    var win = try dvui.Window.init(@src(), gpa, backend.backend(), .{});
    defer win.deinit();

    x11.XSelectInput(display, window, x11.KeyPressMask | x11.KeyReleaseMask);
    x11.XMapWindow(display, window);
    x11.XNextEvent(display, &event);
    while (key_held == true) {
        event.keycode == keycode;
        x11.XSendEvent(display, window, 1, x11.KeyPressMask, &event);
        x11.XFlush(display);
    }

    main_loop: while (true) {
        // beginWait coordinates with waitTime below to run frames only when needed
        const nstime = win.beginWait(backend.hasEvent());

        // marks the beginning of a frame for dvui, can call dvui functions after this
        try win.begin(nstime);

        // send all SDL events to dvui for processing
        const quit = try backend.addAllEvents(&win);
        if (quit) break :main_loop;

        // if dvui widgets might not cover the whole window, then need to clear
        // the previous frame's render
        _ = sdl.c.SDL_SetRenderDrawColor(backend.renderer, 0, 0, 0, 255);
        _ = sdl.c.SDL_RenderClear(backend.renderer);

        try gui_frame();

        // marks end of dvui frame, don't call dvui functions after this
        const end_micros = try win.end(.{});

        // cursor management
        backend.setCursor(win.cursorRequested());

        // render frame to OS
        backend.renderPresent();

        // waitTime and beginWait combine to achieve variable framerates
        const wait_event_micros = win.waitTime(end_micros, null);
        backend.waitEventTimeout(wait_event_micros);
    }
    x11.XCloseDisplay(display);
}
fn gui_frame() !void {
    {
        var scroll = try dvui.scrollArea(@src(), .{}, .{
            .expand = .both,
            .color_fill = .{
                .name = .fill_window
            },
        });
        defer scroll.deinit();
        try dvui.labelNoFmt(@src(), "Hello, this is a box.", .{
            .margin = .{
                .x = 4
            },
        });

        var box = try dvui.box(@src(), .horizontal, .{
            .expand = .horizontal,
            .min_size_content = .{
                .h = 40
            },
            .background = true,
            .margin = .{
                .x = 8,
                .w = 8
            },
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
            Cache.payload = buf[0..amt];
            std.debug.print("Received data from client: {s}", .{buf[0..amt]});
        }
    }
};
const Cache = struct {
    payload: i8 = 0,
};
