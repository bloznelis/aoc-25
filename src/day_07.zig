const std = @import("std");
const Grid = @import("grid.zig");
const inputs = @import("input.zig");

const print = std.debug.print;

const Coords = struct {
    y: usize,
    x: usize,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const gpa = arena.allocator();

    const grid = try Grid.parse(gpa, inputs.realInput);
    var map = std.AutoHashMap(Coords, u64).init(gpa);

    const startX = std.mem.indexOf(u8, grid[0], "S").?;
    const answ = try possiblePaths(gpa, grid, Coords{ .x = startX, .y = 0 }, &map);

    print("{any}\n", .{answ});
}

fn possiblePaths(gpa: std.mem.Allocator, grid: [][]u8, start: Coords, acc: *std.AutoHashMap(Coords, u64)) !u64 {
    const worlds = 1;
    var y = start.y;
    while (true) : (y += 1) {
        if (Grid.gett(grid, y, start.x)) |char| {
            switch (char) {
                '^' => {
                    const current = Coords{ .x = start.x, .y = y };
                    if (acc.get(current)) |cached| {
                        return worlds * cached;
                    } else {
                        const left = try possiblePaths(gpa, grid, Coords{ .x = start.x - 1, .y = y }, acc);
                        const right = try possiblePaths(gpa, grid, Coords{ .x = start.x + 1, .y = y }, acc);
                        const subWorlds = (left + right) * worlds;

                        try acc.put(Coords{ .x = start.x, .y = y }, subWorlds);

                        return (left + right) * worlds;
                    }
                },
                else => continue,
            }
        } else {
            return 1;
        }
    }
}
