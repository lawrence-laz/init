const std = @import("std");
const Context = @import("context.zig").Context;

pub fn unsupportedTemplateKind(context: *const Context, kind: std.fs.File.Kind) void {
    _ = context;
    _ = kind;
}

pub fn templateNotFound(context: *const Context, templates_dir: std.fs.Dir) void {
    std.debug.print(
        \\Template '{s}' not found.
        \\Available templates:
        \\
    , .{context.template_name});
    var templates_iter = templates_dir.iterate();
    while (templates_iter.next() catch null) |template| {
        std.debug.print("    {s}\n", .{template.name});
    }
}
