const std = @import("std");
const inputs = @import("input.zig");

pub fn solve() !u64 {
    const allocator = std.heap.page_allocator;

    var banks = std.mem.splitAny(u8, inputs.realInput, "\n");
    var sum: u64 = 0;

    while (banks.next()) |bank| {
        const bankDigits = try allocator.alloc(u8, bank.len);
        for (bank, 0..) |c, i| {
            bankDigits[i] = try std.fmt.charToDigit(c, 10);
        }

        // var part1Batpack: [2]u8 = .{0} ** 2;
        var part2Batpack: [12]u8 = .{0} ** 12;

        sum += findMaxJoltage(bankDigits, &part2Batpack);
    }

    return sum;
}

fn findMaxJoltage(bank: []u8, batpack: []u8) u64 {
    for (bank, 0..) |batToFit, i| {
        var fitsAtIdx: ?usize = null;
        for (batpack, 0..) |currentBat, j| {
            if (currentBat < batToFit and batpack.len - j <= bank.len - i) {
                fitsAtIdx = j;
                break;
            }
        }

        if (fitsAtIdx) |idx| {
            batpack[idx] = batToFit;
            for (idx + 1..batpack.len) |j| {
                batpack[j] = 0;
            }
        }
    }

    var num: u64 = 0;
    for (batpack) |bat| {
        num = num * 10 + bat;
    }

    return num;
}
