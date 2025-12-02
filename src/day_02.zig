const std = @import("std");
const inputs = @import("input.zig");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Range = struct { start: u64, end: u64 };

pub fn solve() !void {
    const allocator = std.heap.page_allocator;
    var ranges = std.mem.splitAny(u8, inputs.realInput, ",");

    var sum: u64 = 0;
    while (ranges.next()) |range| {
        var it = std.mem.splitAny(u8, range, "-");

        const rang = Range{
            .start = try std.fmt.parseInt(u64, it.next().?, 10),
            .end = try std.fmt.parseInt(u64, it.next().?, 10),
        };

        for (try explode(allocator, rang)) |id| {
            if (isInvalid(id)) {
                sum = sum + id;
            }
        }
    }

    std.debug.print("{d}\n", .{sum});
}

fn explode(allocator: Allocator, range: Range) ![]u64 {
    const size = range.end - range.start + 1;
    var list = try ArrayList(u64).initCapacity(allocator, size);
    defer list.deinit(allocator);

    var i = range.start;
    while (i <= range.end) : (i += 1) {
        list.appendAssumeCapacity(i);
    }

    return try list.toOwnedSlice(allocator);
}

pub fn isInvalid(id: u64) bool {
    var buf: [32]u8 = undefined;
    const slice = std.fmt.bufPrint(&buf, "{}", .{id}) catch unreachable;
    const half = slice.len / 2;

    var i: u32 = 1;
    while (i <= half) : (i += 1) {
        var windowed = std.mem.window(u8, slice, i, i);

        var invalid = true;
        var prev: ?[]const u8 = null;
        while (windowed.next()) |window| : (prev = window) {
            if (window.len < i) {
                invalid = false;
                break;
            }

            if (prev) |previous| {
                if (!std.mem.eql(u8, previous, window)) {
                    invalid = false;
                    break;
                }
            }
        }

        if (invalid) {
            return invalid;
        }
    }

    return false;
}

test "isInvalid()" {
    try std.testing.expect(isInvalid(99));
    try std.testing.expect(isInvalid(999));
    try std.testing.expect(isInvalid(123123));
    try std.testing.expect(isInvalid(123123123));
    try std.testing.expect(!isInvalid(1231231234));
    try std.testing.expect(!isInvalid(98));
}

test "explode inclusive range" {
    const allocator = std.testing.allocator;

    const result = try explode(allocator, .{ .start = 3, .end = 5 });
    defer allocator.free(result);

    try std.testing.expectEqual(3, result.len);
    try std.testing.expectEqual(3, result[0]);
    try std.testing.expectEqual(4, result[1]);
    try std.testing.expectEqual(5, result[2]);
}
