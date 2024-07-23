const clap = @import("clap");
const std = @import("std");
const fs_utils = @import("fs_utils.zig");
const builtin = @import("builtin");
const Context = @import("context.zig").Context;
const error_handler = @import("error_handler.zig");

// TODO: -h and --help
pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const context = try Context.init(arena.allocator());
    defer context.deinit();

    var config_dir = try std.fs.openDirAbsolute(context.config_dir_path, .{});
    defer config_dir.close();

    var templates_dir = try config_dir.openDir("templates", .{ .iterate = true });
    defer templates_dir.close();

    var templates_iter = templates_dir.iterate();
    var maybe_template_dir: ?std.fs.Dir = null;
    while (try templates_iter.next()) |template| {
        if (std.mem.eql(u8, template.name, context.template_name)) {
            if (template.kind == .directory) {
                maybe_template_dir = try templates_dir.openDir(context.template_name, .{});
                std.log.debug("Using template {s}", .{template.name});
            } else {
                error_handler.unsupportedTemplateKind(&context, template.kind);
                return 1;
            }
        }
    }
    defer {
        if (maybe_template_dir) |*template_dir_value| {
            template_dir_value.close();
        }
    }

    if (maybe_template_dir) |template_dir| {
        const template_path = try template_dir.realpathAlloc(arena.allocator(), ".");
        try fs_utils.copyDirAbsolute(&context, template_path, context.current_dir_path);
    } else {
        error_handler.templateNotFound(&context, templates_dir);
        return 1;
    }

    return 0;
}
