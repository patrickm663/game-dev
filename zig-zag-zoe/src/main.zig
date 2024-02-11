const std = @import("std");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

// Some variables used elsewhere
var seed: u64 = undefined;
const rows: u8 = 5;
const cols: u8 = 5;
var play_O: u8 = undefined;
var win_status: u8 = undefined;

pub fn main() !void {

    // init board
    var game_board = [rows][cols]u8{ [_]u8{ 0, 0, 0, 0, 0 }, [_]u8{ 0, 0, 0, 0, 0 }, [_]u8{ 0, 0, 0, 0, 0 }, [_]u8{ 0, 0, 0, 0, 0 }, [_]u8{ 0, 0, 0, 0, 0 } };

    // generate game menu
    try init_game();

    // game loop until grid is filled
    while (true) {
        // HUMAN plays O
        if (play_O == 1) {
            try print_board(game_board);
            try HUMAN_move(&game_board);
            if (!is_active(game_board)) {
                break;
            }
            try print_board(game_board);
            try CPU_move(&game_board);
            if (!is_active(game_board)) {
                break;
            }
            // CPU plays O
        } else if (play_O == 2) {
            try CPU_move(&game_board);
            if (!is_active(game_board)) {
                break;
            }
            try print_board(game_board);
            try HUMAN_move(&game_board);
            if (!is_active(game_board)) {
                break;
            }
            try print_board(game_board);
        }
    }
    try print_board(game_board);
    try stdout.print("GAME OVER!\n", .{});
}

pub fn get_rand(a: u8, b: u8) !u8 {
    // helper function for random numbers between a and b exclusive
    try std.os.getrandom(std.mem.asBytes(&seed));
    var prng = std.rand.DefaultPrng.init(seed);

    const rand = &prng.random();
    const target_num = rand.intRangeAtMost(u8, a, b);

    return target_num;
}

pub fn is_active(board: [rows][cols]u8) bool {
    // checks for 3 in a row
    if (row_check(board) or col_check(board) or diag_check(board)) {
        return false;
    }

    // checks for at least one empty cell for game to continue
    for (board, 0..) |r, r_idx| {
        for (r, 0..) |cell, c_idx| {
            // can't have used vars/captures
            _ = r_idx;
            _ = c_idx;
            if (cell == 0) {
                return true;
            }
        }
    }

    //try stdout.print("DRAW!\n", .{});
    return false;
}

pub fn row_check(board: [rows][cols]u8) bool {
    // checks for at least one set of 3 values in a row
    for (board, 0..) |r, r_idx| {
        for (r, 0..) |cell, c_idx| {
            // only go up to n-3
            if (c_idx < (cols - 2)) {
                if (cell != 0) {
                    if (board[r_idx][c_idx] == board[r_idx][c_idx + 1] and board[r_idx][c_idx + 1] == board[r_idx][c_idx + 2]) {
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

pub fn col_check(board: [rows][cols]u8) bool {
    // checks for at least one set of 3 values in a col
    for (board, 0..) |r, r_idx| {
        for (r, 0..) |cell, c_idx| {
            // only go up to n-3
            if (r_idx < (rows - 2)) {
                if (cell != 0) {
                    if (board[r_idx][c_idx] == board[r_idx + 1][c_idx] and board[r_idx + 1][c_idx] == board[r_idx + 2][c_idx]) {
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

pub fn diag_check(board: [rows][cols]u8) bool {
    // TODO
    _ = board;
    return false;
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
        var CPU_move_x: u8 = try get_rand(0, rows - 1);
        var CPU_move_y: u8 = try get_rand(0, cols - 1);
        var CPU_move_: u8 = 1;

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
        var HUMAN_move_x: u8 = try get_user_input();

        try stdout.print("Enter column number:\n", .{});
        var HUMAN_move_y: u8 = try get_user_input();

        var HUMAN_move_: u8 = 2;

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
    try stdout.print("*************\t\n\n", .{});
    try stdout.print("*ZIG-ZAG-ZOE*\t\n\n", .{});
    try stdout.print("*************\t\n\n", .{});

    while (true) {
        try stdout.print("PLAY FIRST? (1/2)\n", .{});
        try stdout.print("1. Yes\n", .{});
        try stdout.print("2. No\n", .{});
        try stdout.print("3. Help\n", .{});
        try stdout.print("9. Quit Game\n", .{});
        play_O = try get_user_input();

        if (play_O == 1 or play_O == 2) {
            break;
        } else if (play_O == 3) {
            try stdout.print("Zig-Zag-Zoe is a two player game played on a 5x5 board.\n", .{});
            try stdout.print("Players take turns placing Zs and Os until 3-in-a-row/column/diagonal.\n", .{});
            try stdout.print("If the board is full, the game ends in a draw.\n", .{});
        } else if (play_O == 9) {
            try stdout.print("Thanks for playing! Come again!\n", .{});
            std.process.exit(0);
        } else {
            try stdout.print("Invalid entry!\n\n", .{});
        }
    }

    try stdout.print("\n", .{});
}
