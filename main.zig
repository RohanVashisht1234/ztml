const std = @import("std");

pub fn tokenize_line(allocator: std.mem.Allocator, line: []const u8) ![][]const u8 {
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
    if (args.next()) |input_file_name| {
        input_file = input_file_name;
    } else {
        @panic("Input file not specified");
    }
    if (args.next()) |output_file_name| {
        output_file = output_file_name;
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
    var input_file_handle = try std.fs.cwd().openFile(input_file, .{});
    defer input_file_handle.close();

    var input_file_reader = input_file_handle.reader();
    var line_count: u16 = 0;
    var started_tags: u16 = 0; // Count the number of tags that are starting
    var ended_tags: u16 = 0; // Count the number of tags that are ending

    var line_read_buffer: [1024]u8 = undefined;
    while (try input_file_reader.readUntilDelimiterOrEof(&line_read_buffer, '\n')) |input_line| {
        line_count += 1;
        const line = std.mem.trim(u8, input_line, " ");
        if(line.len == 0) continue;

        const line_as_tokens = try tokenize_line(allocator, line);
        defer allocator.free(line_as_tokens);

        if (line.len == 0 or std.mem.startsWith(u8, line, "//")) {
            continue;
        } else if (std.mem.startsWith(u8, line, "{")) {
            if (!std.mem.endsWith(u8, line, "}")) {
                @panic("Error: Did you forget to end the line {} with a '}}' ?");
            } else {
                const replaced_string_level_1 = try std.mem.replaceOwned(u8, allocator, line, "{", " ");
                defer allocator.free(replaced_string_level_1);
                const replaced_string_level_2 = try std.mem.replaceOwned(u8, allocator, replaced_string_level_1, "}", " ");
                defer allocator.free(replaced_string_level_2);
                for (replaced_string_level_2) |char| {
                    try resulting_html.append(char);
                }
            }
        } else if (line_as_tokens.len > 1 and std.mem.eql(u8, line_as_tokens[1], "end")) {
            try resulting_html.append('<');
            try resulting_html.append('/');
            for (line_as_tokens[0]) |char| {
                try resulting_html.append(char);
            }
            try resulting_html.append('>');
            try resulting_html.append('\n');
            ended_tags += 1;
        } else if (line_as_tokens.len > 0 and std.mem.eql(u8, line_as_tokens[line_as_tokens.len - 1], "end")) {
            try resulting_html.append('<');
            for (line_as_tokens) |token| {
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
            started_tags += 1;
        }
    }
    var output_file_handle = try std.fs.cwd().createFile(output_file, .{});
    defer output_file_handle.close();
    const resulting_html_as_string = try resulting_html.toOwnedSlice();
    defer allocator.free(resulting_html_as_string);
    try output_file_handle.writeAll(resulting_html_as_string);

    if (started_tags > ended_tags) {
        std.debug.print("Warning: Number of tags you created don't have their corresponding ending tags!", .{});
    }
    if (started_tags < ended_tags) {
        std.debug.print("Warning: Number of ending tags are greater than the number of starting tags.", .{});
    }
    std.debug.print("Generated {s}.", .{output_file});
}
