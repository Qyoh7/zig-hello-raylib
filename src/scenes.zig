const std = @import("std");
const rl = @import("raylib");
const colors = @import("colors.zig");
const entities = @import("entities.zig");

pub const State = enum {
    menu, gameplay, gameover
};

const BoundingRec = struct {
    leftEdge: f32,
    rightEdge: f32,
    topEdge: f32,
    bottomEdge: f32,
};

pub const Game = struct {
    gameplay: Gameplay,
    menu: Menu = .{},
    gameOverMenu: GameOverMenu = .{},
    state: State = .menu,

    pub fn init() Game
    {
        return Game {
            .gameplay = Gameplay.init(),
        };
    }
};

pub const DebugLines = struct {
    text: []const u8,

    pub fn add(self: *DebugLines, line: []const u8) !void
    {
        const alloc = std.mem.Allocator;
        self.text = try std.fmt.allocPrint(alloc, "{s}{s}\n", .{self.text, line});
        defer alloc.free(self.text);
    }
    pub fn draw(self: *DebugLines) void
    {
        rl.drawText(self.text, 0, 0, 20, .green);
    }
};

pub const Gameplay = struct {
    paddle: entities.Paddle,
    ball: entities.Ball,

    pub fn init() Gameplay {
        const paddleSize : rl.Vector2 = .{
            .x = 100,
            .y = 10,
        };
        const initialPaddlePos : rl.Vector2 = .{
            .x = @as(f32, @floatFromInt(rl.getScreenWidth())) / 2.0 - (paddleSize.x / 2.0),
            .y = @as(f32, @floatFromInt(rl.getScreenHeight())) - paddleSize.y - 15,
        };

        std.debug.print("initial paddle pos: {d}, {d}\n", .{initialPaddlePos.x, initialPaddlePos.y});

        const initialPaddleVel : rl.Vector2 = .{
            .x = 0,
            .y = 0,
        };

        const ballRadius = 5;
        const initialBallPos : rl.Vector2 = .{
            .x = @as(f32, @floatFromInt(rl.getScreenWidth())) / 2.0 - (paddleSize.x / 2.0),
            .y = @as(f32, @floatFromInt(rl.getScreenHeight())) / 2.0 - ballRadius,
        };
        const initialBallVel : rl.Vector2 = .{
            .x = -400,
            .y = -400,
        };

        return Gameplay {
            .paddle = .{
                .size = paddleSize,
                .pos = initialPaddlePos,
                .vel = initialPaddleVel,
                .color = .red,
            },
            .ball = .{
                .radius = 10,
                .pos = initialBallPos,
                .vel = initialBallVel,
                .color = colors.ballColor,
            }
        };
    }

    pub fn draw(self: *Gameplay) void
    {
        rl.drawRectangleV(self.paddle.pos, self.paddle.size, self.paddle.color);
        rl.drawCircleV(self.ball.pos, @floatFromInt(self.ball.radius), self.ball.color);
    }

    fn getBallBoundingRec(self: *Gameplay) BoundingRec
    {
        return BoundingRec {
            .topEdge = self.ball.pos.y -    @as(f32, @floatFromInt(self.ball.radius)),
            .rightEdge = self.ball.pos.x +  @as(f32, @floatFromInt(self.ball.radius)),
            .bottomEdge = self.ball.pos.y + @as(f32, @floatFromInt(self.ball.radius)),
            .leftEdge = self.ball.pos.x -   @as(f32, @floatFromInt(self.ball.radius)),
        };
    }

    fn getPaddleBoundingRec(self: *Gameplay) BoundingRec
    {
        return BoundingRec {
            .topEdge = self.paddle.pos.y,
            .rightEdge = self.paddle.pos.x + self.paddle.size.x,
            .bottomEdge = self.paddle.pos.y + self.paddle.size.y,
            .leftEdge = self.paddle.pos.x,
        };
    }

    fn inRange(value: anytype, min: anytype, max: anytype) bool
    {
        if (@TypeOf(value) == @TypeOf(min) and 
            @TypeOf(min) == @TypeOf(max) and
            @TypeOf(value) == @TypeOf(max)) 
        {
            return (value >= min and value <= max);
        }
        std.log.err("Invalid types in inRange {s}, {s}, and {s}\n", .{@TypeOf(value), @TypeOf(min), @TypeOf(max)});
    }

    pub fn update(self: *Gameplay, state: *State) void
    {
        const dt = rl.getFrameTime();

        // update physics
        self.paddle.pos.x += self.paddle.vel.x * dt;
        self.paddle.pos.y += self.paddle.vel.y * dt;

        self.ball.pos.x += self.ball.vel.x * dt;
        self.ball.pos.y += self.ball.vel.y * dt;

        // check for collision
        if (getBallBoundingRec(self).topEdge <= 0)
        {
            self.ball.pos.y = @floatFromInt(self.ball.radius);
            self.ball.vel.y = -self.ball.vel.y;
        }
        if (getBallBoundingRec(self).rightEdge >= @as(f32, @floatFromInt(rl.getScreenWidth())))
        {
            self.ball.pos.x = @floatFromInt(rl.getScreenWidth() - self.ball.radius);
            self.ball.vel.x = -self.ball.vel.x;
        }
        if (getBallBoundingRec(self).bottomEdge >= @as(f32, @floatFromInt(rl.getScreenHeight())))
        {
            state.* = .gameover;
            self.* = Gameplay.init();
            return;
        }

        if (getBallBoundingRec(self).leftEdge <= 0)
        {
            self.ball.pos.x = @floatFromInt(self.ball.radius);
            self.ball.vel.x = -self.ball.vel.x;
        }
        if (getBallBoundingRec(self).bottomEdge >= self.paddle.pos.y and
            inRange(self.ball.pos.x, self.paddle.pos.x, self.paddle.pos.x + self.paddle.size.x))
        {
            self.ball.pos.y = self.paddle.pos.y - @as(f32, @floatFromInt(self.ball.radius));
            self.ball.vel.y = -self.ball.vel.y;
        }
        if (getPaddleBoundingRec(self).leftEdge <= 0)
        {
            self.paddle.pos.x = 0;
        }
        if (getPaddleBoundingRec(self).rightEdge >= @as(f32, @floatFromInt(rl.getScreenWidth())))
        {
            self.paddle.pos.x = @as(f32, @floatFromInt(rl.getScreenWidth())) - self.paddle.size.x;
        }

        // check for input
        if (rl.isKeyDown(.left) and rl.isKeyDown(.right))
        {
            self.paddle.vel.x = 0;
        }
        else if (rl.isKeyDown(.left))
        {
            self.paddle.vel.x = -500;
        }
        else if (rl.isKeyDown(.right))
        {
            self.paddle.vel.x = 500;
        }
        else
        {
            self.paddle.vel.x = 0;
        }

    }
};

pub const Menu = struct {
    pub fn draw() void
    {
        const text = "Press Enter to start game";
        const textX = @divTrunc(rl.getScreenWidth(), 2) - @divTrunc(rl.measureText(text, 20), 2);
        const textY = @divTrunc(rl.getScreenHeight(), 2);
        const fontSize = 20;
        const textColor = colors.ballColor;
        rl.drawText(text, textX, textY, fontSize, textColor);
    }
    pub fn update(state: *State) void {
        if (rl.isKeyDown(.enter)) {
            state.* = .gameplay;
        }
    }
};

pub const GameOverMenu = struct {
    pub fn draw() void
    {
        const gameOverText = "Game Over!";
        const text = "Press Enter to play again";

        const textX = @divTrunc(rl.getScreenWidth(), 2) - @divTrunc(rl.measureText(text, 20), 2);
        const textY = @divTrunc(rl.getScreenHeight(), 2);
        const fontSize = 20;
        const textColor = colors.ballColor;
        rl.drawText(text, textX, textY, fontSize, textColor);
        rl.drawText(gameOverText, textX, textY - 40, fontSize, .red);
    }

    pub fn update(state: *State) void {
        if (rl.isKeyDown(.enter)) {
            state.* = .gameplay;
        }
    }
};
