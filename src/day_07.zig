const std = @import("std");
const Grid = @import("grid.zig");
const inputs = @import("input.zig");

const print = std.debug.print;

const Coords = struct {
    y: usize,
    x: usize,
    fn left(self: *const Coords) Coords {
        return Coords{ .y = self.y, .x = self.x - 1 };
    }
    fn right(self: *const Coords) Coords {
        return Coords{ .y = self.y, .x = self.x + 1 };
    }
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
    var y = start.y;
    while (Grid.gett(grid, y, start.x)) |char| : (y += 1) {
        switch (char) {
            '^' => {
                const current = Coords{ .x = start.x, .y = y };
                if (acc.get(current)) |cached| {
                    return cached;
                } else {
                    const left = try possiblePaths(gpa, grid, current.left(), acc);
                    const right = try possiblePaths(gpa, grid, current.right(), acc);
                    const subWorlds = (left + right);

                    try acc.put(current, subWorlds);

                    return subWorlds;
                }
            },
            else => continue,
        }
    }

    return 1;
}
