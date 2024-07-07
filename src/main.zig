const clap = @import("clap");
const std = @import("std");
const fs_utils = @import("fs_utils.zig");
const builtin = @import("builtin");
const Context = @import("context.zig").Context;

// TODO: -h and --help
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const context = try Context.init(arena.allocator());
    defer context.deinit();

    var config_dir = try std.fs.openDirAbsolute(context.config_dir_path, .{ .iterate = true });
    defer config_dir.close();

    var templates_dir = try config_dir.openDir("templates", .{ .iterate = true });
    defer templates_dir.close();

    var templates_iter = templates_dir.iterate();
    var template_dir: ?std.fs.Dir = null;

    while (try templates_iter.next()) |template| {
        if (template.kind == .directory and
            std.mem.eql(u8, template.name, context.template_name))
        {
            template_dir = try templates_dir.openDir(template.name, .{});
            std.log.debug("Using template {s}", .{template.name});
        }
    }
    defer {
        if (template_dir) |*template_dir_value| {
            template_dir_value.close();
        }
    }

    const template_path = try template_dir.?.realpathAlloc(arena.allocator(), ".");

    try fs_utils.copyDirAbsolute(&context, template_path, context.current_dir_path);
}
