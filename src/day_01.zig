const std = @import("std");
const inputs = @import("input.zig");

const Part = enum { Part1, Part2 };

pub fn solve(part: Part) !u32 {
    var lines = std.mem.splitAny(u8, inputs.realInput, "\n");

    var dial: i32 = 50;
    var part1Counter: u32 = 0;
    var part2Counter: u32 = 0;

    while (lines.next()) |line| {
        const direction = line[0];
        const clicks = try std.fmt.parseInt(u16, line[1..], 10);

        if (direction == 'L') {
            const dialBefore = dial;
            dial -= clicks;

            if (dial == 0) {
                part2Counter += 1;
            } else if (dial < 0) {
                part2Counter += @abs(@divTrunc(dial, 100));

                if (dialBefore > 0) {
                    part2Counter += 1;
                }
            }
        } else {
            dial += clicks;
            part2Counter += @abs(@divTrunc(dial, 100));
        }

        dial = @mod(dial, 100);

        if (dial == 0) {
            part1Counter += 1;
        }
    }

    return switch (part) {
        Part.Part1 => part1Counter,
        Part.Part2 => part2Counter,
    };
}

test "part 1" {
    try std.testing.expect(try solve(Part.Part1) == 1026);
}

test "part 2" {
    try std.testing.expect(try solve(Part.Part2) == 5923);
}
