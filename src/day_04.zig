const std = @import("std");
const Grid = @import("grid.zig");
const inputs = @import("input.zig");

const print = std.debug.print;

const Coords = struct { y: usize, x: usize };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const gpa = arena.allocator();

    const grid = try Grid.parse(gpa, inputs.realInput);

    const answerP1 = try solveP1(gpa, grid);
    const answerP2 = try solveP2(gpa, grid);
    print("part 1 answer: {any}\n", .{answerP1});
    print("part 2 answer: {any}\n", .{answerP2});
}

pub fn solveP1(gpa: std.mem.Allocator, grid: [][]u8) !usize {
    const reachable = try collectReachable(gpa, grid);
    return reachable.len;
}

fn solveP2(gpa: std.mem.Allocator, grid: [][]u8) !usize {
    var removableCnt: usize = 0;

    while (true) {
        const toRemove = try collectReachable(gpa, grid);

        if (toRemove.len == 0) {
            break;
        }
        removableCnt += toRemove.len;

        for (toRemove) |coords| {
            grid[coords.y][coords.x] = '.';
        }
    }

    return removableCnt;
}

fn collectReachable(gpa: std.mem.Allocator, grid: [][]u8) ![]Coords {
    var acc: std.ArrayList(Coords) = .{};

    for (0..grid.len) |y| {
        for (0..grid[0].len) |x| {
            const isPaper = if (Grid.get(grid, @intCast(y), @intCast(x))) |cell| cell == '@' else false;
            if (!isPaper) continue;

            var paperCnt: u32 = 0;
            const neighs = Grid.getNeighbors(grid, @intCast(y), @intCast(x));
            for (neighs) |neigh| {
                if (neigh == '@') paperCnt += 1;
            }

            if (paperCnt < 4) {
                try acc.append(gpa, Coords{ .y = y, .x = x });
            }
        }
    }

    return acc.toOwnedSlice(gpa);
}
