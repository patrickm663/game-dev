# Zig-Zag-Zoe

**A Docker version and pre-build binaries are coming soon!**

A simple 5x5 version of Tic-Tac-Toe, written in Zig.

Players take turns playing Zs and Os, attempting to get 3-in-a-row. Play continues until one square remains. The player with the most 3-in-a-rows at the end wins.

## Usage
With Zig installed, run the following from the CLI:

```
zig build
```

The binary can be found in `zig-out/bin/zig-zag-zoe` and run using:

```
./zig-out/bin/zig-zag-zoe
```

To compile and run all at once, run:

```
zig build run
```
