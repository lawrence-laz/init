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

    if ((context.template_name == null and context.cli_args.args.list == 0) or
        context.cli_args.args.help != 0)
    {
        std.debug.print(Context.cli_help, .{});
        return 0;
    }

    var config_dir = try std.fs.openDirAbsolute(context.config_dir_path, .{});
    defer config_dir.close();

    var templates_dir = try config_dir.openDir("templates", .{ .iterate = true });
    defer templates_dir.close();

    var templates_iter = templates_dir.iterate();

    if (context.cli_args.args.list != 0) {
        while (try templates_iter.next()) |template| {
            if (template.kind == .directory) {
                std.debug.print("{s}\n", .{template.name});
            }
        }
        return 0;
    } else if (context.template_name) |template_name| {
        var maybe_template_dir: ?std.fs.Dir = null;
        while (try templates_iter.next()) |template| {
            if (std.mem.eql(u8, template.name, template_name)) {
                if (template.kind == .directory) {
                    maybe_template_dir = try templates_dir.openDir(template_name, .{});
                } else {
                    error_handler.unsupportedTemplateKind(template.kind);
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
    } else unreachable;

    return 0;
}
