const std = @import("std");
const inputs = @import("input.zig");

const print = std.debug.print;

const Range = struct {
    start: u64,
    end: u64,
    fn inclusiveSize(self: Range) u64 {
        return self.end - self.start + 1;
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const gpa = arena.allocator();

    var blocks = std.mem.splitSequence(u8, inputs.realInput, "\n\n");
    const rangesBlock = blocks.next().?;
    // const ingredientsBlock = blocks.next().?;

    var rangesAcc: std.ArrayList(Range) = .{};
    // var ingredientsAcc: std.ArrayList(u64) = .{};

    var rangesIt = std.mem.splitAny(u8, rangesBlock, "\n");
    while (rangesIt.next()) |range| {
        var it = std.mem.splitAny(u8, range, "-");
        const start = it.next().?;
        const end = it.next().?;
        print("start: {s} end: {s}\n", .{ start, end });
        try rangesAcc.append(gpa, Range{
            .start = try std.fmt.parseInt(u64, start, 10),
            .end = try std.fmt.parseInt(u64, end, 10),
        });
    }

    // var ingredientsIt = std.mem.splitAny(u8, ingredientsBlock, "\n");
    // while (ingredientsIt.next()) |ingredient| {
    //     try ingredientsAcc.append(gpa, try std.fmt.parseInt(u64, ingredient, 10));
    // }

    var ranges = try rangesAcc.toOwnedSlice(gpa);
    // const ingredients = try ingredientsAcc.toOwnedSlice(gpa);

    ranges = normalizeRanges(ranges);

    for (ranges) |range| {
        print("{any}\n", .{range});
    }

    var rangesAmount: u64 = 0;
    for (ranges) |range| {
        rangesAmount += range.inclusiveSize();
    }

    // var freshCount: u64 = 0;
    // for (ingredients) |ingredient| {
    //     if (isFresh(ingredient, ranges)) freshCount += 1;
    // }

    // 385010328097675 too high
    // 341056515036487 too low
    // 316995189806554 too low
    // 353863745078671 just right
    print("answer: {any}\n", .{rangesAmount});
}

fn isFresh(ingredient: u64, freshnessRanges: []Range) bool {
    for (freshnessRanges) |range| {
        if (range.start <= ingredient and ingredient <= range.end) return true;
    }
    return false;
}

fn normalizeRanges(rangess: []Range) []Range {
    var normalized = false;
    var ranges = rangess;
    while (!normalized) {
        normalized = true;
        for (ranges, 0..) |rangeI, i| {
            for (ranges, 0..) |rangeJ, j| {
                if (rangeI.start == rangeJ.start and rangeI.end == rangeJ.end) {
                    continue;
                }

                //    |--I--|
                // |-------J----|
                if (rangeJ.start <= rangeI.start and rangeI.end <= rangeJ.end) {
                    ranges[i] = ranges[j];
                    normalized = false;
                // |-------I----|
                //    |--J--|
                } else if (rangeI.start <= rangeJ.start and rangeJ.end <= rangeI.end) {
                    ranges[j] = ranges[i];
                    normalized = false;
                // |-----I-----|
                //          |-------J----|
                } else if (rangeI.start <= rangeJ.start and rangeJ.start <= rangeI.end) {
                    ranges[i] = Range{ .start = rangeI.start, .end = rangeJ.end };
                    ranges[j] = Range{ .start = rangeI.start, .end = rangeJ.end };
                    normalized = false;
                //         |-----I-----|
                // |-------J----|
                } else if (rangeJ.start <= rangeI.start and rangeI.start <= rangeJ.end) {
                    ranges[i] = Range{ .start = rangeJ.start, .end = rangeI.end };
                    ranges[j] = Range{ .start = rangeJ.start, .end = rangeI.end };
                    normalized = false;
                }

            }
        }
        ranges = distinct(Range, ranges);
    }

    return ranges;
}

test "isInvalid()" {
    const ranges = [_]Range{
        Range{ .start = 10, .end = 20 },
        Range{ .start = 10, .end = 20 },
    };
    const expected = [_]Range{
        Range{ .start = 10, .end = 20 },
    };
    const result = normalizeRanges(ranges);
    try std.testing.expectEqualSlices(result, expected);
}

//O(n^2)
fn distinct(comptime T: type, slice: []T) []T {
    var write: usize = 0;
    var i: usize = 0;
    while (i < slice.len) : (i += 1) {
        var seen = false;
        var j: usize = 0;
        while (j < write) : (j += 1) {
            if (std.meta.eql(slice[i], slice[j])) {
                seen = true;
                break;
            }
        }
        if (!seen) {
            slice[write] = slice[i];
            write += 1;
        }
    }
    return slice[0..write];
}
