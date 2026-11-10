const std = @import("std");
const rl = @import("raylib");

pub const Ball = struct {
    radius: i32,
    pos: rl.Vector2,
    vel: rl.Vector2,
    color: rl.Color,
};

pub const Paddle = struct {
    size: rl.Vector2,
    pos: rl.Vector2,
    vel: rl.Vector2,
    color: rl.Color,
};
