const std = @import("std");
const Grid = @import("grid.zig");
const inputs = @import("input.zig");

const print = std.debug.print;

const Operation = enum { mul, sum };
const Argument = union(enum) { operation: Operation, value: u32 };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const gpa = arena.allocator();

    const parsed = try parse(gpa, inputs.realInput);
    const colLen = parsed.len;
    const rowLen = parsed[0].len;

    var superSum: u64 = 0;
    for (0..rowLen) |row| {
        switch (parsed[0][row]) {
            .operation => |op| {
                switch (op) {
                    Operation.sum => {
                        var sum: u64 = 0;
                        for (1..colLen) |col| {
                            switch (parsed[col][row]) {
                                .value => |value| {
                                    sum += value;
                                },
                                else => unreachable
                            }
                        }
                        superSum += sum;
                    },
                    Operation.mul => {
                        var product: u64 = 1;
                        for (1..colLen) |col| {
                            switch (parsed[col][row]) {
                                .value => |value| {
                                    product *= value;
                                },
                                else => unreachable
                            }
                        }
                        superSum += product;
                    },
                }
            },
            else => unreachable,
        }
    }

    print("{any}\n", .{superSum});

}

pub fn parse(gpa: std.mem.Allocator, input: []const u8) ![][]Argument {
    var grid: std.ArrayList([]Argument) = .{};
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var row: std.ArrayList(Argument) = .{};
        var rowElements = std.mem.tokenizeScalar(u8, line, ' ');
        while (rowElements.next()) |element| {
            const exp = switch (element[0]) {
                '*' => Argument{ .operation = Operation.mul },
                '+' => Argument{ .operation = Operation.sum },
                else => Argument{ .value = try std.fmt.parseInt(u32, element, 10) },
            };
            try row.append(gpa, exp);
        }
        const slice = try row.toOwnedSlice(gpa);
        try grid.append(gpa, slice);
    }
    const slice = try grid.toOwnedSlice(gpa);
    std.mem.reverse([]Argument, slice);

    return slice;
}

// fuckit here's some clojure for p2:
//
// (defn solve [input]
//   (let [lines (->>
//                input
//                str/trim
//                str/split-lines)
//         nums (->> lines
//                   (drop-last 1)
//                   (map #(str/split % #""))
//                   (apply mapv vector) ;; transpose
//                   (map str/join)
//                   (map str/trim)
//                   (partition-by str/blank?)
//                   (filter #(not= % '("")))
//                   (map #(map read-string %)))
//         ops (->> #""
//                  (str/split (last lines))
//                  (filter #(not (str/blank? %))))]
//     (loop [acc 0
//            [op & rem-ops] ops
//            [nums & rem-nums] nums]
//       (if (nil? op)
//         acc
//         (case op
//           "+" (recur (+ acc (reduce + nums)) rem-ops rem-nums)
//           "*" (recur (+ acc (reduce * nums)) rem-ops rem-nums))))))
