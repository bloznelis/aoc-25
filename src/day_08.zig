const std = @import("std");
const inputs = @import("input.zig");

const print = std.debug.print;

const Coords = struct { x: i64, y: i64, z: i64 };
const Connection = struct { a: Coords, b: Coords };
const ConnectionLen = struct { a: Coords, b: Coords, len: f32 };

fn coordsEqual(a: Coords, b: Coords) bool {
    return a.x == b.x and a.y == b.y and a.z == b.z;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const gpa = arena.allocator();

    var lines = std.mem.splitAny(u8, inputs.testInput, "\n");
    var allCords: std.ArrayList(Coords) = .{};
    while (lines.next()) |line| {
        var it = std.mem.tokenizeAny(u8, line, ",");

        const coords = Coords{
            .x = try std.fmt.parseInt(i64, it.next().?, 10),
            .y = try std.fmt.parseInt(i64, it.next().?, 10),
            .z = try std.fmt.parseInt(i64, it.next().?, 10),
        };

        try allCords.append(gpa, coords);
    }
    var connectionsMap = std.AutoHashMap(Coords, std.ArrayList(Coords)).init(gpa);

    for (allCords.items) |coords| {
        try connectionsMap.put(coords, .{});
    }

    var connections: std.ArrayList(ConnectionLen) = .{};
    var dedup = std.AutoHashMap(Connection, bool).init(gpa);

    for (allCords.items) |a| {
        for (allCords.items) |b| {
            const conLen = ConnectionLen{ .a = a, .b = b, .len = calcDistance(a, b) };
            const con1 = Connection{
                .a = a,
                .b = b,
            };
            const con2 = Connection{
                .a = b,
                .b = a,
            };
            if (!coordsEqual(a, b) and !dedup.contains(con1) and !dedup.contains(con2)) {
                try dedup.put(con1, true);
                try dedup.put(con2, true);
                try connections.append(gpa, conLen);
            }
        }
    }
    std.sort.pdq(ConnectionLen, connections.items, {}, struct {
        fn less(_: void, a: ConnectionLen, b: ConnectionLen) bool {
            return a.len < b.len;
        }
    }.less);

    for (connections.items) |connection| {
        var coordsConnections = connectionsMap.get(connection.a).?;
        try coordsConnections.append(gpa, connection.b);

        var boxConnections = connectionsMap.get(connection.b).?;
        try boxConnections.append(gpa, connection.a);

        try connectionsMap.put(connection.a, coordsConnections);
        try connectionsMap.put(connection.b, boxConnections);

        var left = std.AutoHashMap(Coords, bool).init(gpa);
        try walk(&left, connection.a, &connectionsMap);

        if (left.count() == 20) {
            print("answ {any}\n", .{connection.a.x * connection.b.x});

            break;
        }
    }
}

fn walk(visited: *std.AutoHashMap(Coords, bool), coords: Coords, toVisit: *std.AutoHashMap(Coords, std.ArrayList(Coords))) !void {
    if (visited.contains(coords)) {
        return;
    }
    if (toVisit.get(coords)) |boxes| {
        try visited.put(coords, true);
        for (boxes.items) |box| {
            try walk(visited, box, toVisit);
        }
    }
}

fn findClosestBox(coords: Coords, allBoxes: []Coords) Coords {
    var closestDistance: f32 = std.math.floatMax(f32);
    var closestBox = allBoxes[0];

    for (allBoxes) |box| {
        const dist = calcDistance(coords, box);
        if (!coordsEqual(coords, box) and dist < closestDistance) {
            closestDistance = dist;
            closestBox = box;
        }
    }
    return closestBox;
}

fn calcDistance(this: Coords, that: Coords) f32 {
    const x = std.math.pow(f32, @floatFromInt(this.x - that.x), 2.0);
    const y = std.math.pow(f32, @floatFromInt(this.y - that.y), 2.0);
    const z = std.math.pow(f32, @floatFromInt(this.z - that.z), 2.0);

    return std.math.sqrt(x + y + z);
}
