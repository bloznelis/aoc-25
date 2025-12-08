const std = @import("std");
const inputs = @import("input.zig");

const print = std.debug.print;

const Coords = struct { x: i32, y: i32, z: i32 };
const Connection = struct { a: Coords, b: Coords, len: f32 };
const Connectionn = struct { a: Coords, b: Coords };

fn coordsEqual(a: Coords, b: Coords) bool {
    return a.x == b.x and a.y == b.y and a.z == b.z;
}

fn lessByX(_: void, a: Coords, b: Coords) bool {
    return a.len < b.len;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const gpa = arena.allocator();

    var lines = std.mem.splitAny(u8, inputs.realInput, "\n");
    var allCords: std.ArrayList(Coords) = .{};
    while (lines.next()) |line| {
        var it = std.mem.tokenizeAny(u8, line, ",");

        const coords = Coords{
            .x = try std.fmt.parseInt(i32, it.next().?, 10),
            .y = try std.fmt.parseInt(i32, it.next().?, 10),
            .z = try std.fmt.parseInt(i32, it.next().?, 10),
        };

        try allCords.append(gpa, coords);
    }
    const allCoordsSlice: []Coords = try allCords.toOwnedSlice(gpa);
    var connectionsMap = std.AutoHashMap(Coords, std.ArrayList(Coords)).init(gpa);

    for (allCoordsSlice) |coords| {
        try connectionsMap.put(coords, .{});
        // print("x={any}, y={any}, z={any}\n", .{ coords.x, coords.y, coords.z });
    }

    var connections: std.ArrayList(Connection) = .{};
    var dedup = std.AutoHashMap(Connectionn, bool).init(gpa);

    for (allCoordsSlice) |a| {
        for (allCoordsSlice) |b| {
            const con = Connection{ .a = a, .b = b, .len = calcDistance(a, b) };
            const con1 = Connectionn{
                .a = a,
                .b = b,
            };
            const con2 = Connectionn{
                .a = b,
                .b = a,
            };
            if (!coordsEqual(a, b) and !dedup.contains(con1) and !dedup.contains(con2)) {
                try dedup.put(con1, true);
                try dedup.put(con2, true);
                try connections.append(gpa, con);
            }
        }
    }
    std.sort.pdq(Connection, connections.items, {}, struct {
        fn less(_: void, a: Connection, b: Connection) bool {
            return a.len < b.len;
        }
    }.less);
    const toConnect = connections.items[0..1000];

    for (toConnect) |connection| {
        // const closestBox = findClosestBox(coords, allCoordsSlice);
        // print("connecting {any} => {any}\n", .{ connection.a, connection.b });
        var coordsConnections = connectionsMap.get(connection.a).?;
        try coordsConnections.append(gpa, connection.b);

        var boxConnections = connectionsMap.get(connection.b).?;
        try boxConnections.append(gpa, connection.a);

        try connectionsMap.put(connection.a, coordsConnections);
        try connectionsMap.put(connection.b, boxConnections);
    }

    var sizes: std.ArrayList(u32) = .{};
    var visitIt = connectionsMap.keyIterator();
    while (visitIt.next()) |nextToExplore| {
        var visited = std.AutoHashMap(Coords, bool).init(gpa);
        try walkSize3(&visited, nextToExplore.*, &connectionsMap);
        try sizes.append(gpa, visited.count());
    }
    std.mem.sort(u32, sizes.items, {}, comptime std.sort.desc(u32));

    var sum: u32 = 1;
    for (sizes.items[0..3]) |size| {
        print("size: {any}\n", .{size});
        sum *= size;
    }
    print("answ: {any}\n", .{sum});

    // const closestBox = findClosestBox(allCoordsSlice[0], allCoordsSlice);
    // print("x={any}, y={any}, z={any}\n", .{ closestBox.x, closestBox.y, closestBox.z });
}

fn walkSize3(visited: *std.AutoHashMap(Coords, bool), start: Coords, toVisit: *std.AutoHashMap(Coords, std.ArrayList(Coords))) !void {
    if (visited.contains(start)) {
        return;
    }
    const boxes = toVisit.get(start).?;

    try visited.put(start, true);
    for (boxes.items) |box| {
        try walkSize2(visited, box, toVisit);
    }
}

fn walkSize2(visited: *std.AutoHashMap(Coords, bool), start: Coords, toVisit: *std.AutoHashMap(Coords, std.ArrayList(Coords))) !void {
    if (visited.contains(start)) {
        return;
    }
    const boxes = toVisit.get(start).?;

    for (boxes.items) |box| {
        try visited.put(start, true);
        _ = toVisit.remove(start);
        try walkSize2(visited, box, toVisit);
    }
}

fn walkSize(visited: *std.AutoHashMap(Coords, bool), start: Coords, connections: std.AutoHashMap(Coords, std.ArrayList(Coords))) !void {
    if (visited.contains(start)) {
        return;
    }
    const boxes = connections.get(start).?;

    for (boxes.items) |box| {
        try visited.put(start, true);
        try walkSize(visited, box, connections);
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
