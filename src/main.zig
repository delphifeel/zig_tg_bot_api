const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const log = std.log;
const time = std.time;
const string_utils = @import("bot_api/utils/string.zig");
const string = string_utils.string;
const stringEq = string_utils.stringEq;
const Bot = @import("bot_api/bot_api.zig");

const SLEEP_TIME = 1 * 1000 * 1000 * 1000;

fn readIntroText(allocator: Allocator) !string {
    return try std.fs.cwd().readFileAlloc(allocator, "data/intro.txt", 16000);
}

fn sendInfo(bot: *Bot, chat_id: u64) !void {
    _ = chat_id;
    _ = bot;
    // TODO: not implemented
}

fn sendBack(bot: *Bot, chat_id: u64, text: string) !void {
    return try bot.sendMessage(chat_id, text, .{});
}

pub fn main() !void {
    log.info("Telegram Bot Health Checker. Started\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa.detectLeaks() == false);
    var allocator = gpa.allocator();

    var bot_token = try std.process.getEnvVarOwned(allocator, "TOKEN");
    defer allocator.free(bot_token);

    var introText = try readIntroText(allocator);
    defer allocator.free(introText);

    var bot = try Bot.init(allocator, bot_token);
    defer bot.deinit();
    bot.enableDebug(true);
    while (true) {
        var updates = try bot.getUpdates(allocator) orelse {
            std.debug.print("getUpdates error\n", .{});
            continue;
        };
        defer updates.deinit();
        for (updates.getSlice()) |*update| {
            var message = update.getMessage() orelse continue;

            if (!message.isCommand()) { // ignore any non-command Messages
                continue;
            }

            var command = message.command() orelse continue;

            if (stringEq(command, "/start")) {
                try sendBack(bot, message.chatId(), introText);
            } else if (stringEq(command, "/info")) {} else {
                try sendInfo(bot, message.chatId());
            }

            // switch (message.command()) {
            //     "/get1" => sendVideoWithMetadata(bot, message, VIDEO_1),
            //     "/get2" => sendVideoWithMetadata(bot, message, VIDEO_2),
            //     "/get3" => sendVideoWithMetadata(bot, message, VIDEO_3),
            // }
        }

        time.sleep(SLEEP_TIME);
    }
}

// test "botApi" {
//     var allocator = std.testing.allocator;
//     var bot = try Bot.init(allocator, BOT_TOKEN);
//     defer bot.deinit();
//     bot.enableDebug(true);
//     var i: u32 = 0;
//     while (true) {
//         var updates = try bot.getUpdates(allocator) orelse {
//             std.debug.print("getUddates error\n", .{});
//             continue;
//         };
//         defer updates.deinit();
//         for (updates.getSlice()) |*update| {
//             var message = update.getMessage() orelse continue;

//             if (!message.isCommand()) { // ignore any non-command Messages
//                 continue;
//             }

//             var command = message.command() orelse continue;

//             if (utils.stringEq(command, "/start")) {
//                 try sendBack(bot, message.chatId(), introText);
//             } else {
//                 std.debug.print("unknown command: {s}\n", .{command});
//             }

//             // switch (message.command()) {
//             //     "/start" => ,
//             //     "/info" => sendInfo(bot, message.Chat.ID),
//             //     "/get1" => sendVideoWithMetadata(bot, message, VIDEO_1),
//             //     "/get2" => sendVideoWithMetadata(bot, message, VIDEO_2),
//             //     "/get3" => sendVideoWithMetadata(bot, message, VIDEO_3),
//             // }

//         }
//         i += 1;
//         if (i == 3) {
//             break;
//         }
//     }
// }
