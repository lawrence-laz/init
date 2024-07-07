const std = @import("std");
const Context = @import("context.zig").Context;

pub fn copyDirAbsolute(context: *const Context, source_path: []const u8, target_path: []const u8) !void {
    var source_dir = try std.fs.openDirAbsolute(source_path, .{ .iterate = true });
    defer source_dir.close();

    const target_path_params_replaced = try replaceParamsAlloc(context, target_path);

    if (!doesFileOrDirExistAbsolute(target_path_params_replaced)) {
        try std.fs.makeDirAbsolute(target_path_params_replaced);
    }
    var target_dir = try std.fs.openDirAbsolute(target_path_params_replaced, .{ .iterate = true });
    defer target_dir.close();

    try copyDir(context, source_dir, target_dir);
}

pub fn copyDir(context: *const Context, source_dir: std.fs.Dir, target_dir: std.fs.Dir) !void {
    var source_dir_iter = source_dir.iterate();
    while (try source_dir_iter.next()) |subelement| {
        switch (subelement.kind) {
            .file => {
                if (doesFileOrDirExist(target_dir, subelement.name)) {
                    var path_buffer: [std.fs.max_path_bytes]u8 = undefined;
                    std.log.err("File '{s}' already exists.", .{try target_dir.realpath(subelement.name, &path_buffer)});
                    return error.FileAlreadyExsits;
                }

                const source_file = try source_dir.openFile(subelement.name, .{});
                defer source_file.close();
                const source_content = try source_file.readToEndAlloc(context.allocator, 0xFFFFF);
                const target_content = try replaceParamsAlloc(context, source_content);
                const target_file_name = try replaceParamsAlloc(context, subelement.name);
                const target_file = try target_dir.createFile(target_file_name, .{});
                defer target_file.close();
                try target_file.writeAll(target_content);
            },
            .directory => {
                var source_subdir = try source_dir.openDir(subelement.name, .{ .iterate = true });
                defer source_subdir.close();
                const target_subdir_name = try replaceParamsAlloc(context, subelement.name);
                if (!doesFileOrDirExist(target_dir, target_subdir_name)) {
                    try target_dir.makeDir(target_subdir_name);
                }
                var target_subdir = try target_dir.openDir(target_subdir_name, .{ .iterate = true });
                defer target_subdir.close();
                try copyDir(context, source_subdir, target_subdir);
            },
            else => {
                // Ignoring other stuff for now.
            },
        }
    }
}

fn doesFileOrDirExist(dir: std.fs.Dir, subpath: []const u8) bool {
    dir.access(subpath, .{}) catch return false;
    return true;
}

fn doesFileOrDirExistAbsolute(path: []const u8) bool {
    std.fs.accessAbsolute(path, .{}) catch return false;
    return true;
}

fn replaceParamsAlloc(context: *const Context, input: []const u8) ![]const u8 {
    if (context.template_params.keys().len == 0) {
        return input;
    }
    var current: []const u8 = input;
    // TODO: This is inefficient, need to revisit.
    for (context.template_params.keys()) |key| {
        const replace_key = try std.mem.concat(context.allocator, u8, &[3][]const u8{ "___", key, "___" });
        const replace_value = context.template_params.get(key).?;
        current = try std.mem.replaceOwned(u8, context.allocator, current, replace_key, replace_value);
    }
    return current;
}
