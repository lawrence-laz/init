const std = @import("std");

// https://adventofcode.com/2024/day/???
fn solvePart1(input: []const u8) !u32 {
    _ = input;
    return 123;
}

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(input);
    try std.testing.expectEqual(123, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(input);
    try std.testing.expectEqual(123, result);
}

fn solvePart2(input: []const u8) !u32 {
    _ = input;
    return 123;
}

test "example input part2" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart2(input);
    try std.testing.expectEqual(123, result);
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart2(input);
    try std.testing.expectEqual(123, result);
}
