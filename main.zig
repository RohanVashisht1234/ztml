const std = @import("std");

pub fn split_line(allocator: std.mem.Allocator, line: []const u8) ![][]const u8 {
    var list = std.ArrayList([]const u8).init(allocator);
    defer list.deinit();
    var iter = std.mem.splitScalar(u8, line, ' ');

    while (iter.next()) |word| {
        try list.append(word);
    }
    return try list.toOwnedSlice();
}

pub fn main() !void {
    // Get sys args
    var args = std.process.args();
    _ = args.skip();
    var input_file: [:0]const u8 = undefined;
    var output_file: [:0]const u8 = undefined;
    if (args.next()) |ok| {
        input_file = ok;
    } else {
        @panic("Input file not specified");
    }
    if (args.next()) |ok| {
        output_file = ok;
    } else {
        @panic("Output file not specified");
    }

    // Permanent allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("Not enough RAM on computer.");
    }
    var resulting_html = std.ArrayList(u8).init(allocator);
    defer resulting_html.deinit();
    // Read file line by line
    var file = try std.fs.cwd().openFile(input_file, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var line_count: u16 = 0;
    var started: u16 = 0; // Count the number of tags that are starting
    var ended: u16 = 0; // Count the number of tags that are ending

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |input_line| {
        line_count += 1;
        const line = std.mem.trim(u8, input_line, " ");
        switch (line.len) {
            0 => continue,
            else => {},
        }
        const tokens = try split_line(allocator, line);
        defer allocator.free(tokens);

        if (line.len == 0 or std.mem.startsWith(u8, line, "//")) {
            continue;
        } else if (std.mem.startsWith(u8, line, "{")) {
            if (!std.mem.endsWith(u8, line, "}")) {
                @panic("Error: Did you forget to end the line {} with a '}}' ?");
            } else {
                const completed_1 = try std.mem.replaceOwned(u8, allocator, line, "{", " ");
                defer allocator.free(completed_1);
                const completed_2 = try std.mem.replaceOwned(u8, allocator, completed_1, "}", " ");
                defer allocator.free(completed_2);
                for (completed_2) |char| {
                    try resulting_html.append(char);
                }
            }
        } else if (tokens.len > 1 and std.mem.eql(u8, tokens[1], "end")) {
            try resulting_html.append('<');
            try resulting_html.append('/');
            for (tokens[0]) |char| {
                try resulting_html.append(char);
            }
            try resulting_html.append('>');
            try resulting_html.append('\n');
            ended += 1;
        } else if (tokens.len > 0 and std.mem.eql(u8, tokens[tokens.len - 1], "end")) {
            try resulting_html.append('<');
            for (tokens[0 .. tokens.len - 1]) |token| {
                for (token) |char| {
                    try resulting_html.append(char);
                }
                try resulting_html.append(' ');
            }
            try resulting_html.append('/');
            try resulting_html.append('>');
            try resulting_html.append('\n');
        } else {
            try resulting_html.append('<');
            for (line) |char| {
                try resulting_html.append(char);
            }
            try resulting_html.append('>');
            started += 1;
        }
    }
    var fo = try std.fs.cwd().createFile(output_file, .{});
    defer fo.close();
    const res = try resulting_html.toOwnedSlice();
    defer allocator.free(res);
    try fo.writeAll(res);

    if (started > ended) {
        std.debug.print("Warning: Number of tags you created don't have their corresponding ending tags!", .{});
    }
    if (started < ended) {
        std.debug.print("Warning: Number of ending tags are greater than the number of starting tags.", .{});
    }
}
