const std = @import("std");

pub fn tokenizeLine(allocator: std.mem.Allocator, line: []const u8) ![][]const u8 {
    var list = std.ArrayList([]const u8).init(allocator);
    defer list.deinit();
    var iter = std.mem.splitScalar(u8, line, ' ');

    while (iter.next()) |word| {
        try list.append(word);
    }
    return try list.toOwnedSlice();
}

pub fn parser(variables_storage: *std.StringArrayHashMap([]const u8), allocator: std.mem.Allocator, input_file: []const u8) ![]const u8 {
    var resulting_html = std.ArrayList(u8).init(allocator);
    errdefer resulting_html.deinit();
    // Read file line by line
    var input_file_handle = std.fs.cwd().openFile(input_file, .{}) catch {
        std.log.err("Input file not found: \"{s}\"", .{input_file});
        std.process.exit(1);
    };

    defer input_file_handle.close();

    var line_count: u16 = 0;
    var started_tags: u16 = 0; // Count the number of tags that are starting
    var ended_tags: u16 = 0; // Count the number of tags that are ending

    var buf: [1024]u8 = undefined;
    var buf_stream = std.io.fixedBufferStream(&buf);
    var eof = false;
    while (!eof) : (line_count += 1) {
        input_file_handle.reader().streamUntilDelimiter(buf_stream.writer(), '\n', 1024) catch |e| switch (e) {
            error.EndOfStream => eof = true,
            else => break,
        };
        defer buf_stream.reset();
        const input_line = buf_stream.getWritten();
        // defer allocator.free(input_line);
        const line = std.mem.trim(u8, input_line, " ");

        if (line.len == 0 or std.mem.startsWith(u8, line, "//")) continue;

        const line_as_tokens = try tokenizeLine(allocator, line);
        defer allocator.free(line_as_tokens);
        if (std.mem.startsWith(u8, line, "{")) {
            if (!std.mem.endsWith(u8, line, "}")) {
                std.log.err("Error: Did you forget to end the line {} with a '}}' ?", .{line_count});
                std.process.exit(1);
            } else {
                const replaced_string_level_1 = try std.mem.replaceOwned(u8, allocator, line, "{", " ");
                defer allocator.free(replaced_string_level_1);
                const replaced_string_level_2 = try std.mem.replaceOwned(u8, allocator, replaced_string_level_1, "}", " ");
                defer allocator.free(replaced_string_level_2);
                try resulting_html.appendSlice(replaced_string_level_2);
            }
        } else if (std.mem.startsWith(u8, line, "#define")) {
            var iter = std.mem.splitScalar(u8, line, ':');
            _ = iter.next().?;
            const variable_name = iter.next() orelse {
                std.log.err("You have made some mistake in variable declaration in line number: {}.\n", .{line_count});
                std.log.err("The correct way of declaring variable is:\n", .{});
                std.log.err("#define:variable_name:Variable content\n", .{});
                std.process.exit(1);
            };
            const variable_content = iter.next() orelse {
                std.log.err("You have made some mistake in variable declaration in line number: {}.\n", .{line_count});
                std.log.err("The correct way of declaring variable is:\n", .{});
                std.log.err("#define:variable_name:Variable content\n", .{});
                std.process.exit(1);
            };
            const key = try allocator.dupe(u8, variable_name);
            const value = try allocator.dupe(u8, variable_content);
            try variables_storage.*.put(key, value);
        } else if (std.mem.startsWith(u8, line, "#include")) {
            var iter = std.mem.splitScalar(u8, line, ':');
            _ = iter.next().?;
            const variable_name = iter.next() orelse {
                std.log.err("You have made some mistake in variable declaration in line number: {}.\n", .{line_count});
                std.log.err("The correct way of declaring variable is:\n", .{});
                std.log.err("#include:variable_name:file_name\n", .{});
                std.process.exit(1);
            };
            const file_name = iter.next() orelse {
                std.log.err("You have made some mistake in variable declaration in line number: {}.\n", .{line_count});
                std.log.err("The correct way of declaring variable is:\n", .{});
                std.log.err("#include:variable_name:file_name\n", .{});
                std.process.exit(1);
            };
            const actual_content = try parser(variables_storage, allocator, file_name);
            defer allocator.free(actual_content);
            const key = try allocator.dupe(u8, variable_name);
            const value = try allocator.dupe(u8, actual_content);
            try variables_storage.*.put(key, value);
        } else if (std.mem.startsWith(u8, line, "%")) {
            var iter = std.mem.splitScalar(u8, line, '%');
            _ = iter.next().?;
            const variable_name = iter.next().?;
            try resulting_html.appendSlice(variables_storage.*.get(variable_name).?);
        } else if (line_as_tokens.len > 1 and std.mem.eql(u8, line_as_tokens[1], "end")) {
            try resulting_html.appendSlice("</");
            try resulting_html.appendSlice(line_as_tokens[0]);
            try resulting_html.appendSlice(">\n");
            ended_tags += 1;
        } else if (line_as_tokens.len > 0 and std.mem.eql(u8, line_as_tokens[line_as_tokens.len - 1], "end")) {
            try resulting_html.append('<');
            for (line_as_tokens) |token| {
                try resulting_html.appendSlice(token);
                try resulting_html.append(' ');
            }
            try resulting_html.appendSlice("/>\n");
        } else {
            try resulting_html.append('<');
            try resulting_html.appendSlice(line);
            try resulting_html.append('>');
            started_tags += 1;
        }
    }

    if (started_tags > ended_tags) {
        std.log.warn("Warning: Number of tags you created don't have their corresponding ending tags in file: {s}!\n", .{input_file});
    } else if (started_tags < ended_tags) {
        std.log.warn("Warning: Number of ending tags are greater than the number of starting tags in file: {s}!\n", .{input_file});
    }
    return try resulting_html.toOwnedSlice();
}

pub fn main() !void {
    // Get sys args
    var args = std.process.args();
    _ = args.skip();

    const input_file = args.next() orelse {
        std.log.err("Input file not specified", .{});
        std.process.exit(1);
    };
    const output_file = args.next() orelse {
        std.log.err("Input file not specified", .{});
        std.process.exit(1);
    };
    if (args.next()) |extra_unnessecary_argument| {
        std.log.err("An extra unnessecary argument was added: {s}", .{extra_unnessecary_argument});
        std.process.exit(1);
    }

    // Permanent allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("Code contains bugs.");
    }

    var variables = std.StringArrayHashMap([]const u8).init(allocator);
    defer variables.deinit();
    const result = try parser(&variables, allocator, input_file);
    defer allocator.free(result);
    try std.fs.cwd().writeFile(.{
        .sub_path = output_file,
        .data = result,
        .flags = .{},
    });
    defer for (variables.keys(), variables.values()) |key, value| {
        allocator.free(key);
        allocator.free(value);
    };

    std.debug.print("\nGenerated {s}.\n", .{output_file});
}
