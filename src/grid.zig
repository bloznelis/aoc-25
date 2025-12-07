const std = @import("std");

pub fn parse(gpa: std.mem.Allocator, input: []const u8) ![][]u8 {
    var grid: std.ArrayList([]u8) = .{};
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const row = try gpa.alloc(u8, line.len);
        std.mem.copyForwards(u8, row, @ptrCast(line));
        try grid.append(gpa, row);
    }
    return try grid.toOwnedSlice(gpa);
}

pub fn getNeighbors(grid: [][]u8, y: i32, x: i32) [8]?u8 {
    return .{
        get(grid, y + 1, x),
        get(grid, y + 1, x + 1),
        get(grid, y, x + 1),
        get(grid, y - 1, x + 1),
        get(grid, y - 1, x),
        get(grid, y - 1, x - 1),
        get(grid, y, x - 1),
        get(grid, y + 1, x - 1),
    };
}


pub fn gett(grid: [][]u8, y: usize, x: usize) ?u8 {
    if (getOrNull([]u8, grid, y)) |row| {
        return getOrNull(u8, row, x);
    } else {
        return null;
    }
}

pub fn get(grid: [][]u8, y: i32, x: i32) ?u8 {
    const xx: usize = if (x >= 0) @intCast(x) else return null;
    const yy: usize = if (y >= 0) @intCast(y) else return null;

    if (getOrNull([]u8, grid, yy)) |row| {
        return getOrNull(u8, row, xx);
    } else {
        return null;
    }
}

pub fn getOrNull(comptime T: type, slice: []const T, index: usize) ?T {
    return if (index < slice.len) slice[index] else null;
}
