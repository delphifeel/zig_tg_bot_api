const std = @import("std");
const assert = std.debug.assert;
const log = std.log;
const Bot = @import("bot_api.zig");

const BOT_TOKEN = "5958520989:AAESG_D6As4ITx2UooYFNnUTQqfQ5RxdOP8";

const RespStruct = struct {
    ok: bool,
    result: struct {
        id: u64,
        is_bot: bool,
        first_name: []const u8,
        username: []const u8,
        can_join_groups: bool,
        can_read_all_group_messages: bool,
        supports_inline_queries: bool,
    },
};

pub fn main() !void {
    log.info("Telegram Bot Health Checker. Started\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa.detectLeaks() == false);
    var allocator = gpa.allocator();

    var bot = Bot{
        .allocator = allocator,
        .debug = true,
        .token = BOT_TOKEN,
    };
    var resp = try bot.request("getMe", RespStruct);
    defer resp.deinit();
    log.info("{}", .{resp.body});
}

test "botApi" {
    var bot = Bot{
        .allocator = &std.testing.allocator,
        .debug = true,
        .token = BOT_TOKEN,
    };
    var resp = try bot.request("getMe", RespStruct);
    defer resp.deinit();
    log.info("{}", .{resp.body});
}
