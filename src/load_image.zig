const std = @import("std");
const builtin = @import("builtin");
const ArrayList = std.ArrayList;
const fs = std.fs;
const process = std.process;
const eqlIgnoreCase = std.ascii.eqlIgnoreCase;
const time = std.time;
const Allocator = std.mem.Allocator;


// const ray = @import("raylib");
const ray = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
    @cInclude("rlgl.h");
});

pub fn ray_main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 8 }){};
    const allocator = gpa.allocator();
    defer {
        switch (gpa.deinit()) {
            .leak => @panic("leaked memory"),
            else => {},
        }
    }

    const args = try process.argsAlloc(allocator);
    defer process.argsFree(allocator, args);
    const paths_list: ArrayList([:0]const u8) = try if (args.len > 1)
        walkDirectory(args[1], allocator) catch |err| label: {
            std.debug.print("found error {}. Trying local directory\n", .{err});
            break :label walkDirectory(".", allocator);
        }
    else
        walkDirectory(".", allocator);
    defer deinitPathList(paths_list, allocator);
    // std.debug.print("first arg is {s}\n",.{args[1]});
    
    var current_index: usize = 0;
    const max_index = paths_list.items.len;

    const width = 800;
    const height = 450;

    ray.SetConfigFlags(ray.FLAG_MSAA_4X_HINT | ray.FLAG_VSYNC_HINT | ray.FLAG_WINDOW_RESIZABLE);
    ray.InitWindow(width, height, "Nana Cosmetic great imagine viewer");
    ray.SetWindowMinSize(width, height);
    defer ray.CloseWindow();

    var camera: ray.Camera2D = undefined;
    camera.zoom = 1;

    var image: ray.Image = ray.LoadImage(paths_list.items[0]);
    defer ray.UnloadImage(image);
    var texture: ray.Texture2D = createTexture(image, 800, 450);
    defer ray.UnloadTexture(texture);

    var timer = try time.Timer.start();
    const second = 1000_000_000;
    const lazy_mode_timeout = 5 * second;
    const active_mode_timeout = 30 * second;
    var timeout: u64 = lazy_mode_timeout; // timeout in nanoseconds. 1ns=10^9 seconds
    // ray.UnloadImage(image);
    while (!ray.WindowShouldClose()) {
        const screen_width = ray.GetScreenWidth();
        const screen_height = ray.GetScreenHeight();
        if (ray.IsMouseButtonPressed(ray.MOUSE_BUTTON_RIGHT)) {
            try openFileDirectory(paths_list.items[current_index], allocator);
        }
        if (ray.IsKeyPressed(ray.KEY_RIGHT) or ray.IsKeyPressed(ray.KEY_UP)) {
            ray.UnloadImage(image);
            ray.UnloadTexture(texture);
            current_index = (current_index + 1) % max_index;
            image = ray.LoadImage(paths_list.items[current_index]);

            texture = createTexture(image, screen_width, screen_height);

            timer.reset();
            timeout = active_mode_timeout;
        }
        if (ray.IsKeyPressed(ray.KEY_LEFT) or ray.IsKeyPressed(ray.KEY_DOWN)) {
            ray.UnloadImage(image);
            ray.UnloadTexture(texture);
            if (current_index == 0) {
                current_index = max_index - 1;
            } else {
                current_index = (current_index - 1) % max_index;
            }
            image = ray.LoadImage(paths_list.items[current_index]);
            texture = createTexture(image, screen_width, screen_height);

            timer.reset();
            timeout = active_mode_timeout;
        }
        if (timer.read() > timeout) {
            ray.UnloadImage(image);
            ray.UnloadTexture(texture);
            current_index = (current_index + 1) % max_index;
            image = ray.LoadImage(paths_list.items[current_index]);

            texture = createTexture(image, screen_width, screen_height);

            timer.reset();
            timeout = lazy_mode_timeout;
        }
        if (ray.IsWindowResized()) {
            ray.UnloadTexture(texture);
            texture = createTexture(image, screen_width, screen_height);
        }
        if (ray.IsKeyPressed(ray.KEY_SPACE)) {
            camera.zoom = 1;
            camera.target = .{ .x = 0, .y = 0 };
            camera.offset = .{ .x = 0, .y = 0 };
        }
        if (ray.IsMouseButtonDown(ray.MOUSE_BUTTON_LEFT)) {
            var delta = ray.GetMouseDelta();
            delta = ray.Vector2Scale(delta, -1 / camera.zoom);
            camera.target = ray.Vector2Add(camera.target, delta);
        }
        {
            var wheel = ray.GetMouseWheelMove();
            if (wheel != 0) {
                var mouse_world_pos = ray.GetScreenToWorld2D(ray.GetMousePosition(), camera);
                camera.offset = ray.GetMousePosition();
                camera.target = mouse_world_pos;
                const zoom_inc: f32 = 0.125;
                camera.zoom += wheel * zoom_inc;
                if (camera.zoom < zoom_inc)
                    camera.zoom = zoom_inc;
            }
        }
        // Rendering sections
        {
            ray.BeginDrawing();
            defer ray.EndDrawing();
            ray.ClearBackground(ray.WHITE);

            ray.BeginMode2D(camera);
            defer ray.EndMode2D();

            ray.DrawTexture(texture, @divFloor(screen_width, 2) - @divFloor(texture.width, 2), @divFloor(screen_height, 2) - @divFloor(texture.height, 2), ray.WHITE);
            // ray.DrawTexture(texture,0 ,0, ray.WHITE);
            const photo_number = try std.fmt.allocPrintZ(allocator, "photo {d}/{d}", .{ (current_index + 1), max_index });
            defer allocator.free(photo_number);

            {
                ray.rlPushMatrix();
                defer ray.rlPopMatrix();
                var bottom_left_pos = ray.GetScreenToWorld2D(.{ .x = 0, .y = @floatFromInt(screen_height) }, camera);
                ray.rlTranslatef(bottom_left_pos.x, bottom_left_pos.y, 0);
                const text_len = ray.MeasureText(photo_number, 20);
                ray.DrawRectangle(0, -30, text_len + 10, 22, ray.ColorAlpha(ray.BLACK, 0.7));
                ray.DrawText(photo_number, 5, -30, 20, ray.WHITE);
            }
        }
    }
}

/// return a list paths of images as []const u8. must free each path
pub fn walkDirectory(path: []const u8, allocator: Allocator) !ArrayList([:0]const u8) {
    var list = ArrayList([:0]const u8).init(allocator);

    var iter_dir = try fs.cwd().openIterableDir(path, .{ .access_sub_paths = true, .no_follow = false });
    defer iter_dir.close();

    var walker = try iter_dir.walk(allocator);
    defer walker.deinit();

    errdefer deinitPathList(list, allocator);

    while (walker.next()) |entry_optional| {
        if (entry_optional) |entry| {
            if (imageExtension(entry.basename)) {
                var dir = entry.dir;
                const entry_path = try dir.realpathAlloc(allocator, entry.basename);
                defer allocator.free(entry_path);

                const len = entry_path.len;
                var file_path = try allocator.alloc(u8, len + 1);
                std.mem.copyBackwards(u8, file_path, entry_path);
                file_path[len] = 0;
                errdefer allocator.free(file_path);

                try list.append(file_path[0..len :0]);
            }
        } else {
            break;
        }
    } else |err| {
        std.debug.print("got error {}\n", .{err});
    }
    return list;
}
pub fn deinitPathList(list: ArrayList([:0]const u8), allocator: Allocator) void {
    for (list.items) |items| {
        allocator.free(items);
    }
    list.deinit();
}
fn imageExtension(name: []const u8) bool {
    var i = name.len - 1;
    while (i > 0) : (i -= 1) {
        if (name[i] == '.') {
            const extension = name[i + 1 ..];
            return eqlIgnoreCase(extension, "png") or
                eqlIgnoreCase(extension,"jpg") or
                eqlIgnoreCase(extension,"jpeg") or
                eqlIgnoreCase(extension,"gif");
            // return std.mem.eql(u8, "png", extension) or
            //     std.mem.eql(u8, "jpg", extension) or
            //     std.mem.eql(u8, "jpeg", extension) or
            //     std.mem.eql(u8, "gif", extension);
        }
    } else {
        return false;
    }
}
// TODO: Optimize createTexture since LoadingTexture is expensive.
fn createTexture(image: ray.Image, width: c_int, height: c_int) ray.Texture2D {
    var image_copy = ray.ImageCopy(image);
    resizeImage(&image_copy, width, height);
    var texture = ray.LoadTextureFromImage(image_copy);

    ray.UnloadImage(image_copy);
    return texture;
}
fn resizeImage(image: [*c]ray.Image, width: c_int, height: c_int) void {
    const heightf: f64 = @floatFromInt(image.*.height);
    const widthf: f64 = @floatFromInt(image.*.width);
    // check if the aspect ratio of the image is bigger than that of the proposed (width , height)
    if (image.*.width * height > image.*.height * width) {
        const correct_height: c_int = @intFromFloat((heightf / widthf) * @as(f64, @floatFromInt(width)));
        ray.ImageResizeNN(@constCast(image), width, correct_height);
    } else {
        const correct_width: c_int = @intFromFloat((widthf / heightf) * @as(f64, @floatFromInt(height)));
        ray.ImageResizeNN(@constCast(image), correct_width, height);
    }
}

fn openFileDirectory(file_name: [:0]const u8, allocator: Allocator) !void {
    std.debug.print("trying to open {s}. with {}\n",.{file_name, builtin.os.tag});

    const process_args = switch (builtin.os.tag) {
        // open explorer with focus on file_name
        .windows => .{ "explorer.exe", "/select,", file_name },
        // primitive implementation to test on linux
        .linux => .{ "thunar", file_name },
        else => .{ "open", fs.path.dirname(file_name) orelse return error.RootDir },
    };
    var build_process = std.ChildProcess.init(&process_args, allocator);
    try build_process.spawn();

    const term = try build_process.wait();
    switch (term) {
        .Exited => |exited| {
            if (exited == 2) return error.OpenFailed;
        },
        else => return,
    }
}
