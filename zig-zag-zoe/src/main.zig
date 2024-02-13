// Author: Patrick Moehrke
// License: MIT
// Feel free to copy/paste anything you find below!

const std = @import("std");

// can't declare these as global constants on Windows
var stdout: std.fs.File.Writer = undefined;
var stdin: std.fs.File.Reader = undefined;

// Some variables used elsewhere
var seed: u64 = undefined;
const rows: u8 = 5;
const cols: u8 = 5;
var play_O: u8 = undefined;
var played_first: bool = false;
var HUMAN_win_tally: u8 = 0;
var CPU_win_tally: u8 = 0;

pub fn main() !void {
    stdout = std.io.getStdOut().writer();
    stdin = std.io.getStdIn().reader();

    // init board
    var game_board = [rows][cols]u8{ [_]u8{ 0, 0, 0, 0, 0 }, [_]u8{ 0, 0, 0, 0, 0 }, [_]u8{ 0, 0, 0, 0, 0 }, [_]u8{ 0, 0, 0, 0, 0 }, [_]u8{ 0, 0, 0, 0, 0 } };

    // generate game menu and initiate vars
    try init_game();

    // game loop until one cell remaining
    while (true) {
        if (play_O == 1 and !played_first) {
            // HUMAN move first
            try stdout.print("HUMAN SCORE: {}\n\n", .{HUMAN_win_tally});
            try stdout.print("CPU SCORE: {}\n\n", .{CPU_win_tally});
            try print_board(game_board);
            try HUMAN_move(&game_board);
            played_first = true;
        }

        // CPU move
        try clear_screen();
        try CPU_move(&game_board);
        try print_board(game_board);
        CPU_win_tally = count_win(game_board, 1);
        if (!is_active(game_board)) {
            break;
        }

        // HUMAN move
        try clear_screen();
        try stdout.print("HUMAN SCORE: {}\n\n", .{HUMAN_win_tally});
        try stdout.print("CPU SCORE: {}\n\n", .{CPU_win_tally});
        try print_board(game_board);
        try HUMAN_move(&game_board);
        HUMAN_win_tally = count_win(game_board, 2);
        if (!is_active(game_board)) {
            break;
        }
    }

    try clear_screen();
    try print_board(game_board);
    try end_game();
}

pub fn get_rand(a: u8, b: u8) !u8 {
    // helper function for random numbers between a and b exclusive
    try std.os.getrandom(std.mem.asBytes(&seed));
    var prng = std.rand.DefaultPrng.init(seed);

    const rand = &prng.random();
    const target_num = rand.intRangeAtMost(u8, a, b);

    return target_num;
}

pub fn count_win(board: [rows][cols]u8, play_num: u8) u8 {
    // checks for 3 in a row
    return (row_check(board, play_num) + col_check(board, play_num) + diag_check(board, play_num));
}

pub fn is_active(board: [rows][cols]u8) bool {
    // checks for only one empty cell to end game
    var count_zeros: u8 = 0;

    for (board, 0..) |r, r_idx| {
        for (r, 0..) |cell, c_idx| {
            // can't have unused vars/captures
            _ = r_idx;
            _ = c_idx;
            if (cell == 0) {
                count_zeros += 1;
                if (count_zeros > 1) {
                    return true;
                }
            }
        }
    }

    return false;
}

pub fn row_check(board: [rows][cols]u8, play_num: u8) u8 {
    // checks for at least one set of 3 values in a row
    var count_wins: u8 = 0;
    for (board, 0..) |r, r_idx| {
        for (r, 0..) |cell, c_idx| {
            // only go up to n-3
            if (c_idx < (cols - 2)) {
                if (cell == play_num) {
                    if (board[r_idx][c_idx] == board[r_idx][c_idx + 1] and board[r_idx][c_idx + 1] == board[r_idx][c_idx + 2]) {
                        count_wins += 1;
                    }
                }
            }
        }
    }
    return count_wins;
}

pub fn col_check(board: [rows][cols]u8, play_num: u8) u8 {
    // checks for at least one set of 3 values in a col
    var count_wins: u8 = 0;
    for (board, 0..) |r, r_idx| {
        for (r, 0..) |cell, c_idx| {
            // only go up to n-3
            if (r_idx < (rows - 2)) {
                if (cell == play_num) {
                    if (board[r_idx][c_idx] == board[r_idx + 1][c_idx] and board[r_idx + 1][c_idx] == board[r_idx + 2][c_idx]) {
                        count_wins += 1;
                    }
                }
            }
        }
    }
    return count_wins;
}

pub fn diag_check(board: [rows][cols]u8, play_num: u8) u8 {
    // check all diagonals
    var count_wins: u8 = 0;
    // y=x diagonal
    for (board, 0..) |r, r_idx| {
        for (r, 0..) |cell, c_idx| {
            // only check between 2 to rows and 2 to cols
            if (r_idx > 1 and c_idx > 1) {
                if (cell == play_num) {
                    if (board[r_idx][c_idx] == board[r_idx - 1][c_idx - 1] and board[r_idx - 1][c_idx - 1] == board[r_idx - 2][c_idx - 2]) {
                        count_wins += 1;
                    }
                }
            }
        }
    }

    // y=-x diagonal
    for (board, 0..) |r, r_idx| {
        for (r, 0..) |cell, c_idx| {
            // only check between 2 to rows and 2 to cols
            if (r_idx < (rows - 2) and c_idx > 1) {
                if (cell == play_num) {
                    if (board[r_idx][c_idx] == board[r_idx + 1][c_idx - 1] and board[r_idx + 1][c_idx - 1] == board[r_idx + 2][c_idx - 2]) {
                        count_wins += 1;
                    }
                }
            }
        }
    }

    return count_wins;
}

pub fn print_board(board: [rows][cols]u8) !void {
    // Loops over the board and prints a very basic grid
    for (board, 0..) |r, r_idx| {
        for (r, 0..) |cell, c_idx| {
            _ = c_idx;
            if (cell == 0) {
                try stdout.print("| . ", .{});
            } else if (cell == play_O) {
                try stdout.print("| Z ", .{});
            } else {
                try stdout.print("| O ", .{});
            }
        }
        // print row number at the end
        try stdout.print("|  {}\n", .{r_idx});
    }
    try stdout.print("\n", .{});

    // print col numbers after the grid
    var i: u8 = 0;
    while (i < cols) : (i += 1) {
        try stdout.print("  {} ", .{i});
    }
    try stdout.print("\n\n", .{});
}

pub fn CPU_move(board: *[rows][cols]u8) !void {
    // cycles random moves until first free cell
    try stdout.print("CPU MOVE\n", .{});

    while (true) {
        const CPU_move_x: u8 = try get_rand(0, rows - 1);
        const CPU_move_y: u8 = try get_rand(0, cols - 1);
        const CPU_move_: u8 = 1;

        if (is_valid(board, CPU_move_x, CPU_move_y)) {
            board[CPU_move_x][CPU_move_y] = CPU_move_;
            break;
        }
    }
}

pub fn is_valid(board: *[rows][cols]u8, x_move: u8, y_move: u8) bool {
    // checks empty cell
    if (x_move >= 0 and x_move < rows and y_move >= 0 and y_move < cols) {
        return board[x_move][y_move] == 0;
    } else {
        return false;
    }
}

pub fn HUMAN_move(board: *[rows][cols]u8) !void {
    // get player input via terminal
    try stdout.print("HUMAN MOVE\n", .{});

    while (true) {
        try stdout.print("Enter row number:\n", .{});
        const HUMAN_move_x: u8 = get_user_input() catch unreachable;

        try stdout.print("Enter column number:\n", .{});
        const HUMAN_move_y: u8 = get_user_input() catch unreachable;

        const HUMAN_move_: u8 = 2;

        if (is_valid(board, HUMAN_move_x, HUMAN_move_y) and HUMAN_move_ >= 1 and HUMAN_move_ <= (rows * cols)) {
            board[HUMAN_move_x][HUMAN_move_y] = HUMAN_move_;
            try stdout.print("\n", .{});
            break;
        } else {
            try stdout.print("Invalid entry!\n\n", .{});
        }
    }
}

pub fn get_user_input() !u8 {
    // helper for parsing user input
    var user_input: u8 = 31;
    while (true) {
        const bare_line = try stdin.readUntilDelimiterAlloc(
            std.heap.page_allocator,
            '\n',
            8192,
        );
        defer std.heap.page_allocator.free(bare_line);
        const line = std.mem.trim(u8, bare_line, "\r");

        user_input = std.fmt.parseInt(u8, line, 10) catch |err| switch (err) {
            error.InvalidCharacter => {
                try stdout.print("Please enter a number!\n\n", .{});
                continue;
            },
            error.Overflow => {
                try stdout.print("Invalid entry\n\n", .{});
                continue;
            },
        };
        if (user_input != 31) {
            break;
        }
    }
    return user_input;
}

pub fn init_game() !void {
    // loop until user provides input to start game
    try clear_screen();
    try stdout.print("*************\t\n\n", .{});
    try stdout.print("*ZIG-ZAG-ZOE*\t\n\n", .{});
    try stdout.print("*************\t\n\n", .{});

    while (true) {
        try stdout.print("PLAY FIRST? (1/2)\n", .{});
        try stdout.print("1. Yes\n", .{});
        try stdout.print("2. No\n", .{});
        try stdout.print("3. Help\n", .{});
        try stdout.print("9. Quit Game\n", .{});
        play_O = get_user_input() catch unreachable;

        if (play_O == 1 or play_O == 2) {
            try clear_screen();
            break;
        } else if (play_O == 3) {
            try stdout.print("\n* Zig-Zag-Zoe is a two player game played on a 5x5 board.\n", .{});
            try stdout.print("* Players take turns placing Zs and Os, scoring a point for each 3-in-a-row/column/diagonal.\n", .{});
            try stdout.print("* Play continues until only 1 cell remains.\n", .{});
            try stdout.print("* The player with the most points at the end of the game wins.\n\n", .{});
        } else if (play_O == 9) {
            try stdout.print("Thanks for playing! Come again!\n", .{});
            std.process.exit(0);
        } else {
            try stdout.print("Invalid entry!\n\n", .{});
        }
    }

    try stdout.print("\n", .{});
}

pub fn end_game() !void {
    // Print game score and win statys
    try stdout.print("GAME OVER!\n", .{});
    try stdout.print("{} - {}\n", .{ HUMAN_win_tally, CPU_win_tally });

    if (HUMAN_win_tally > CPU_win_tally) {
        try stdout.print("PLAYER WINS!\n", .{});
    } else if (HUMAN_win_tally < CPU_win_tally) {
        try stdout.print("CPU WINS!\n", .{});
    } else {
        try stdout.print("DRAW!\n", .{});
    }
}

pub fn clear_screen() !void {
    // Clear screen and place cursor at top left
    // Source: https://ziggit.dev/t/how-to-clear-terminal/88/1
    try stdout.print("\x1B[2J\x1B[H", .{});
}
