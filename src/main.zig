const std = @import("std");
// const process = std.process;
// const fs = std.fs;
// const ray = @import("raylib.zig");
// const example = @import("basic01.zig");
// const example = @import("camera_zoom.zig");
const example = @import("load_image.zig");
const dynamic = @import("dynamic_load.zig");
// you can use
// zig build-exe src/main -lc -lraylib
// or zig build-exe -I ./include/ -lc src/main.zig lib/libraylib.a
// or just zig build run
pub fn main() !void {
    // try dynamic.dynMain();

    try example.ray_main();
    try hints();

    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allocator = gpa.allocator();
    // defer {
    //     switch (gpa.deinit()) {
    //         .leak => @panic("OOPSIE WOOPSIE!! Uwu We made a fucky wucky!! A wittle fucko boingo! The code monkeys at our headquarters are working VEWY HAWD to fix this!"),
    //         else => {},
    //     }
    // }
    // // _ = allocator;
    // const args = try process.argsAlloc(allocator);
    // defer process.argsFree(allocator, args);

    // var dir = fs.cwd();
    
    // const name = try dir.realpathAlloc(allocator,"assets/IMG_20230528_165209.jpg");
    // defer allocator.free(name);

    // std.debug.print("name is {s}\n",.{name});
    
    // var list = try if(args.len>1)
    //     example.walkDirectory(args[1],allocator) catch |err| label: {
    //         std.debug.print("found error {}. Trying local directory\n",.{err});
    //         break :label example.walkDirectory(".", allocator);
    // } else example.walkDirectory(".", allocator);
    // // var list = try example.walkDirectory(args[1],allocator);
    // defer {
    //     for(list.items) |item| {
    //         allocator.free(item);
    //     }
    //     list.deinit();
    // }
    // for(list.items) |item| {
    //     std.debug.print("{s}\n",.{item});
    // }
    // const file_name_tests = &[_][]const u8{"salim.org","okay.jpg","nice/okay.x.y.png", "cache"};

    // for(file_name_tests) |name| {
    //     if(imageExtension(name)) {
    //         std.debug.print("{s} is an image\n",.{name});
    //     } else {
    //         std.debug.print("{s} is NOT an image\n",.{name});
    //     }
    // }
    // walkDirectory("assets") catch @panic("fuck me");
    
}



fn hints() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("\n⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯\n", .{});
    try stdout.print("Here are some hints:\n", .{});
    try stdout.print("Run `zig build --help` to see all the options\n", .{});
    try stdout.print("Run `zig build -Doptimize=ReleaseSmall` for a small release build\n", .{});
    try stdout.print("Run `zig build -Doptimize=ReleaseSmall -Dstrip=true` for a smaller release build, that strips symbols\n", .{});
    try stdout.print("Run `zig build -Draylib-optimize=ReleaseFast` for a debug build of your application, that uses a fast release of raylib (if you are only debugging your code)\n", .{});

    try bw.flush(); // don't forget to flush!
}
