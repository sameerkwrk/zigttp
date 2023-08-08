const std = @import("std");
const Payload = struct { message: []u8 };
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
        try std.io.getStdOut().writer().print("{any}", .{parsed_json.?.value});
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

// const headers = buf[0..start];
// try std.io.getStdOut().writer().print("\nHeaders >\n{s}\n", .{headers});
// const f1 = std.mem.indexOf(u8, headers, "\n");
// if (f1) |value| {
//     const l1 = headers[0..value];
//     try std.io.getStdOut().writer().print("{s}", .{l1});
// }
