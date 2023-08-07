const std = @import("std");
const Payload = struct { message: []u8 };

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const address = std.net.Address.initIp4([4]u8{ 127, 0, 0, 1 }, 8000);
    var server = std.net.StreamServer.init(.{ .reuse_address = true });
    try server.listen(address);
    while (true) {
        const conn = try server.accept();
        defer conn.stream.close();
        var writer = try conn.stream.writer().write("Hello from theflask");
        _ = writer;

        var buf: [1024]u8 = undefined;
        _ = try conn.stream.readAll(&buf);
        const start_of_json = std.mem.indexOf(u8, &buf, "{");
        const end_of_json = std.mem.lastIndexOf(u8, &buf, "}");
        if (start_of_json) |start| {
            if (end_of_json) |end| {
                const json = try std.json.parseFromSlice(Payload, allocator, buf[start .. end + 1], .{});
                try std.io.getStdOut().writer().print("\nIncoming Request With Data >\n{s}\n{any}\n", .{ buf[start .. end + 1], json.value });
                defer json.deinit();
                const headers = buf[0..start];
                try std.io.getStdOut().writer().print("\nHeaders >\n{s}\n", .{headers});
                const f1 = std.mem.indexOf(u8, headers, "\n");
                if (f1) |value| {
                    const l1 = headers[0..value];
                    try std.io.getStdOut().writer().print("{s}", .{l1});
                }
            } else {
                try std.io.getStdOut().writer().print("{s}", .{"No Ending Found "});
            }
        } else {
            try std.io.getStdOut().writer().print("{s}", .{"Incoming Request With Data >\nNo JSON Found\n "});
        }
        // get_headers()
    }
}

// fn get_headers(head_buffer: []u8) [[]u8]u8 {
//     try std.io.getStdOut().writer().print("{s}", .{head_buffer});
// }
