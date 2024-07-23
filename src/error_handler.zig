const std = @import("std");
const Context = @import("context.zig").Context;

pub fn unsupportedTemplateKind(kind: std.fs.File.Kind) void {
    std.debug.print(
        \\Template kind '{}' is not supported.
        \\Template must be a directory.
        \\
    , .{kind});
}

pub fn templateNotFound(context: *const Context, templates_dir: std.fs.Dir) void {
    std.debug.print(
        \\Template '{s}' not found.
        \\Available templates:
        \\
    , .{context.template_name});
    var templates_iter = templates_dir.iterate();
    while (templates_iter.next() catch null) |template| {
        if (template.kind != .directory) {
            continue;
        }
        std.debug.print("    {s}\n", .{template.name});
    }
}
