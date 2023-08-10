const std = @import("std");
const Payload = struct { message: []u8 };
const Methods = enum { GET, PUT, POST, DELETE };
const Headers = struct {
    method: Methods,
    http: u8,
};
const allocator = std.heap.page_allocator;

pub fn main() !void {
    const address = std.net.Address.initIp4([4]u8{ 127, 0, 0, 1 }, 8000);
    var server = std.net.StreamServer.init(.{ .reuse_address = true });
    try server.listen(address);
    while (true) {
        const conn = try server.accept();
        defer conn.stream.close();
        _ = try conn.stream.write(&[6]u8{ 1, 1, 2, 3, 4, 4 });
        var buf: [1024]u8 = undefined;
        _ = try conn.stream.readAll(&buf);
        var parsed_json = try parse_json(&buf);
        defer if (parsed_json) |json| {
            json.deinit();
        };
        var parsed_headers = try get_hearders(&buf);
        defer if (parsed_headers) |header| {
            header.deinit();
        };
        try std.io.getStdOut().writer().print("{any}\n", .{parsed_json.?.value});
        for (parsed_headers.?.items) |header| {
            try std.io.getStdOut().writer().print("{s}\n", .{header});
        }
    }
}

pub fn parse_json(buf: *[1024]u8) !?std.json.Parsed(Payload) {
    const start_of_json = std.mem.indexOf(u8, buf, "{");
    const end_of_json = std.mem.lastIndexOf(u8, buf, "}");
    if (start_of_json) |start| {
        if (end_of_json) |end| {
            const json = try std.json.parseFromSlice(Payload, allocator, buf[start .. end + 1], .{});
            return json;
        } else {
            try std.io.getStdOut().writer().print("{s}", .{"No Ending Found "});
            return null;
        }
    } else {
        try std.io.getStdOut().writer().print("{s}", .{"Incoming Request With Data >\nNo JSON Found\n "});
        return null;
    }
}

pub fn get_hearders(buf: *[1024]u8) !?std.ArrayList([]const u8) {
    const end_of_headers = std.mem.indexOf(u8, buf, "{");
    if (end_of_headers) |start| {
        const headers = buf[0..start];
        var split = std.mem.splitScalar(u8, headers, '\n');
        var headers_array = std.ArrayList([]const u8).init(allocator);
        while (split.next()) |header| {
            try headers_array.append(header);
        }
        return headers_array;
    } else {
        return null;
    }
}
