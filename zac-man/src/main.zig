// Author: Patrick Moehrke
// License: MIT
// Feel free to copy/paste anything you find below!

const std = @import("std");

// can't declare these as global constants on Windows
var stdout: std.fs.File.Writer = undefined;
var stdin: std.fs.File.Reader = undefined;

// Some variables used elsewhere
var seed: u64 = undefined;
const grid_X: u16 = 5;
const grid_Y: u16 = 10;
const snake: u8 = 1;
const apple: u8 = 2;

pub fn main() !void {
    stdout = std.io.getStdOut().writer();
    stdin = std.io.getStdIn().reader();

    // init board
    var game_screen = [grid_X][grid_Y]u8{ [_]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, [_]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, [_]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, [_]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, [_]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 } };

    game_screen[3][3] = apple;

    var pre_x_pos: u16 = 0;
    var pre_y_pos: u16 = 0;
    game_screen[pre_x_pos][pre_y_pos] = snake;

    var x_pos: u16 = 0;
    var y_pos: u16 = 0;
    var x_pos_: i16 = 0;
    var y_pos_: i16 = 0;
    var x_dt: i16 = 0;
    var y_dt: i16 = 0;
    var dir: i16 = 1;
    var user_move = [2]i16{ 0, 0 };

    var i: u64 = 0;

    try clear_screen();

    while (i < 25) {
        try print_board(game_screen);
        try stdout.print("Iteration: {}\n\n", .{i});
        user_move = try get_user_input();
        x_dt = user_move[0] * dir;
        y_dt = user_move[1] * dir;
        x_pos_ += x_dt;
        y_pos_ += y_dt;
        if (is_valid(x_pos_, y_pos_)) {
            x_pos = @as(u16, @intCast(x_pos_));
            y_pos = @as(u16, @intCast(y_pos_));
            game_screen[pre_x_pos][pre_y_pos] = 0;
            game_screen[x_pos][y_pos] = snake;
            pre_x_pos = x_pos;
            pre_y_pos = y_pos;
            i += 1;

            try print_board(game_screen);
            //_ = try get_user_input();
            //std.time.sleep(500000000);

        } else {
            x_pos_ -= x_dt;
            y_pos_ -= y_dt;
            dir *= -1;

            //try clear_screen();
        }
        try clear_screen();
    }
    try print_board(game_screen);
    try stdout.print("Iteration: {}\n\n", .{i});
}

pub fn is_valid(x_pos: i16, y_pos: i16) bool {
    // check move is within bounds
    return x_pos >= 0 and x_pos < grid_X and y_pos >= 0 and y_pos < grid_Y;
}

pub fn clear_screen() !void {
    // Clear screen and place cursor at top left
    // Source: https://ziggit.dev/t/how-to-clear-terminal/88/1
    try stdout.print("\x1B[2J\x1B[H", .{});
}

pub fn get_rand(a: i16, b: i16) !i16 {
    // helper function for random numbers between a and b exclusive
    try std.os.getrandom(std.mem.asBytes(&seed));
    var prng = std.rand.DefaultPrng.init(seed);

    const rand = &prng.random();
    const target_num = rand.intRangeAtMost(i16, a, b);

    return target_num;
}

pub fn print_board(board: [grid_X][grid_Y]u8) !void {
    // Loops over the board and prints a very basic grid
    for (board, 0..) |r, r_idx| {
        for (r, 0..) |cell, c_idx| {
            _ = r_idx;
            _ = c_idx;
            if (cell == 0) {
                try stdout.print(" . ", .{});
            } else if (cell == snake) {
                try stdout.print(" @ ", .{});
            } else if (cell == apple) {
                try stdout.print(" * ", .{});
            }
        }
        try stdout.print("\n", .{});
    }

    try stdout.print("\n\n", .{});
}

pub fn get_user_input() ![2]i16 {
    // helper for parsing user input
    // 0 = y dir (rows); 1 = x dir (cols)
    var output = [2]i16{ 0, 0 };
    while (true) {
        const bare_line = try stdin.readUntilDelimiterAlloc(
            std.heap.page_allocator,
            '\n',
            8192,
        );
        defer std.heap.page_allocator.free(bare_line);
        const user_input = std.mem.trim(u8, bare_line, "\r");

        // up
        if (std.mem.eql(u8, user_input, "w")) {
            output[0] = -1;
            output[1] = 0;
            break;
            // down
        } else if (std.mem.eql(u8, user_input, "s")) {
            output[0] = 1;
            output[1] = 0;
            break;
            // right
        } else if (std.mem.eql(u8, user_input, "d")) {
            output[0] = 0;
            output[1] = 1;
            break;
            // left
        } else if (std.mem.eql(u8, user_input, "a")) {
            output[0] = 0;
            output[1] = -1;
            break;
        } else {
            continue;
        }
    }
    return output;
}
