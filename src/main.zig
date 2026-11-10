const std = @import("std");
const rl = @import("raylib");
const colors = @import("colors.zig");
const scenes = @import("scenes.zig");
const Game = scenes.Game;

pub fn main() !void {
    const screenWidth = 800;
    const screenHeight = 600;
    const border : rl.Rectangle = .{
        .x = 0,
        .y = 0,
        .width = screenWidth,
        .height = screenHeight
    };


    rl.initWindow(screenWidth, screenHeight, "breakout");
    defer rl.closeWindow();

    var breakout = Game.init();

    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();

        switch (breakout.state)
        {
            .menu => {
                scenes.Menu.update(&breakout.state);
                scenes.Menu.draw();
            },
            .gameplay => {
                breakout.gameplay.update(&breakout.state);
                breakout.gameplay.draw();
            }
        }
        rl.clearBackground(colors.backgroundColor);
        rl.drawRectangleLinesEx(border, 1, .green);

        rl.endDrawing();
    }
}
