const clap = @import("clap");
const std = @import("std");
const fs_utils = @import("fs_utils.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\-c, --config <str>     Config directory path.
        \\<str>
        \\
    );

    var diagnostic = clap.Diagnostic{};
    var args = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diagnostic,
        .allocator = gpa.allocator(),
    }) catch |err| {
        diagnostic.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer args.deinit();

    const config_dir_path: []const u8 = args.args.config orelse return error.MissingConfig;

    if (args.positionals.len != 1) {
        std.log.err("Provide a single parameter specifying a template name: init template-name", .{});
        return;
    }

    const requested_template_name = args.positionals[0];

    const current_dir = std.fs.cwd();
    var current_dir_path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const current_dir_path = try current_dir.realpath(".", &current_dir_path_buf);

    // TODO: Add configurable and use default OS folders, also add a parameter to change the path.
    var config_dir = try std.fs.openDirAbsolute(config_dir_path, .{ .iterate = true });
    defer config_dir.close();
    var templates_dir = try config_dir.openDir("templates", .{ .iterate = true });
    defer templates_dir.close();
    var templates_iter = templates_dir.iterate();
    var template_dir: ?std.fs.Dir = null;
    while (try templates_iter.next()) |template| {
        if (template.kind == std.fs.File.Kind.directory and
            std.mem.eql(u8, template.name, requested_template_name))
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

    var template_path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const template_path = try template_dir.?.realpath(".", &template_path_buf);

    try fs_utils.copyDirAbsolute(template_path, current_dir_path);
}
