const std = @import("std");
const assert = std.debug.assert;
const log = std.log;
const time = std.time;
const Bot = @import("bot_api/bot_api.zig");

const BOT_TOKEN = "";

const SLEEP_TIME = 2 * 1000 * 1000 * 1000;

pub fn main() !void {
    log.info("Telegram Bot Health Checker. Started\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa.detectLeaks() == false);
    var allocator = gpa.allocator();

    var bot = try Bot.init(allocator, BOT_TOKEN);
    defer bot.deinit();
    bot.enableDebug(true);
    var i: u32 = 0;
    while (true) {
        var updates = try bot.getUpdates(allocator);
        defer updates.deinit();
        for (updates.getSlice()) |update_object| {
            if (update_object.message) |msg| {
                std.debug.print("msg: {?s}\n", .{msg.text});
            }
        }
        time.sleep(SLEEP_TIME);

        i += 1;
        if (i == 3) {
            break;
        }
    }
}

test "botApi" {
    var bot = try Bot.init(std.testing.allocator, BOT_TOKEN);
    defer bot.deinit();
    bot.enableDebug(true);
    var i: u64 = 0;
    while (i < 3) {
        var updates = try bot.getUpdates(std.testing.allocator);
        defer updates.deinit();
        for (updates.getSlice()) |update_object| {
            if (update_object.message) |msg| {
                std.debug.print("msg: {?s}\n", .{msg.text});
            }
        }
        time.sleep(SLEEP_TIME);
        i += 1;
    }
}
