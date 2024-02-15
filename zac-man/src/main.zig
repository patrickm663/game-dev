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

    game_screen[4][5] = apple;

    var score: u16 = 0;

    var pre_x_pos: u16 = 1;
    var pre_y_pos: u16 = 1;
    game_screen[pre_x_pos][pre_y_pos] = snake;

    var x_pos: u16 = 0;
    var y_pos: u16 = 0;
    var x_pos_: i16 = 1;
    var y_pos_: i16 = 1;
    var r_apl_x: u16 = 0;
    var r_apl_y: u16 = 0;
    var x_dt: i16 = 0;
    var y_dt: i16 = 0;
    var dir: i16 = 1;
    var user_move = [2]i16{ x_pos_, y_pos_ };

    try clear_screen();

    while (true) {
        try clear_screen();
        try print_board(game_screen);
        try stdout.print("Score: {}\n\n", .{score});
        user_move = try get_user_input();
        x_dt = user_move[0] * dir;
        y_dt = user_move[1] * dir;
        x_pos_ += x_dt;
        y_pos_ += y_dt;
        // check for boundaries
        if (is_valid(x_pos_, y_pos_)) {
            try clear_screen();
            x_pos = @as(u16, @intCast(x_pos_));
            y_pos = @as(u16, @intCast(y_pos_));
            // If the apple gets eaten, place it somewhere else
            if (game_screen[x_pos][y_pos] == apple) {
                while (true) {
                    r_apl_x = @as(u16, @intCast(try get_rand(1, grid_X - 2)));
                    r_apl_y = @as(u16, @intCast(try get_rand(1, grid_Y - 2)));
                    if (r_apl_x != x_pos or r_apl_y != y_pos) {
                        game_screen[r_apl_x][r_apl_y] = apple;
                        break;
                    }
                }
                score += 1;
            }
            game_screen[pre_x_pos][pre_y_pos] = 0;
            game_screen[x_pos][y_pos] = snake;
            pre_x_pos = x_pos;
            pre_y_pos = y_pos;

            // reverse previous move if boundary reached
        } else {
            x_pos_ -= x_dt;
            y_pos_ -= y_dt;
        }
        //  dir *= -1;

        try clear_screen();
    }
    try print_board(game_screen);
    try stdout.print("Score: {}\n\n", .{score});
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
    var user_input: u8 = undefined;
    var output = [2]i16{ 0, 0 };
    user_input = try stdin.readByte();

    // up
    if (user_input == 'w') {
        output[0] = -1;
        output[1] = 0;
        // down
    } else if (user_input == 's') {
        output[0] = 1;
        output[1] = 0;
        // right
    } else if (user_input == 'd') {
        output[0] = 0;
        output[1] = 1;
        // left
    } else if (user_input == 'a') {
        output[0] = 0;
        output[1] = -1;
        // quit
    } else if (user_input == 'q') {
        std.process.exit(1);
    }

    return output;
}
