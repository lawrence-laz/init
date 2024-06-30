const std = @import("std");

pub fn copyDirAbsolute(source_path: []const u8, target_path: []const u8) !void {
    var source_dir = try std.fs.openDirAbsolute(source_path, .{ .iterate = true });
    defer source_dir.close();

    if (!doesFileOrDirExistAbsolute(target_path)) {
        try std.fs.makeDirAbsolute(target_path);
    }
    var target_dir = try std.fs.openDirAbsolute(target_path, .{ .iterate = true });
    defer target_dir.close();

    try copyDir(source_dir, target_dir);
}

pub fn copyDir(source_dir: std.fs.Dir, target_dir: std.fs.Dir) !void {
    var source_dir_iter = source_dir.iterate();
    while (try source_dir_iter.next()) |subelement| {
        switch (subelement.kind) {
            .file => {
                if (doesFileOrDirExist(target_dir, subelement.name)) {
                    var path_buffer: [std.fs.max_path_bytes]u8 = undefined;
                    std.log.err("File '{s}' already exists.", .{try target_dir.realpath(subelement.name, &path_buffer)});
                    return error.FileAlreadyExsits;
                }
                try source_dir.copyFile(subelement.name, target_dir, subelement.name, .{});
            },
            .directory => {
                var source_subdir = try source_dir.openDir(subelement.name, .{ .iterate = true });
                defer source_subdir.close();
                if (!doesFileOrDirExist(target_dir, subelement.name)) {
                    try target_dir.makeDir(subelement.name);
                }
                var target_subdir = try target_dir.openDir(subelement.name, .{ .iterate = true });
                defer target_subdir.close();
                try copyDir(source_subdir, target_subdir);
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
