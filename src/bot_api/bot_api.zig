const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const log = std.log;
const http = @import("http.zig");
const Updates = @import("updates.zig");
const Message = @import("message.zig");
const ApiClient = @import("api_client.zig");
const string = @import("utils.zig").string;

const Bot = @This();

allocator: Allocator,
apiClient: *ApiClient,
lastUpdateId: u32 = 0,

pub fn sendMessage(bot: *Bot, chat_id: u64, text: string) !void {
    var url = try std.fmt.allocPrint(bot.allocator, "sendMessage?chat_id={d}&text={s}", .{
        chat_id,
        text,
    });
    defer bot.allocator.free(url);

    var messageHolder = try bot.apiClient.request(bot.allocator, url, Message) orelse return;
    defer messageHolder.deinit();
}

pub inline fn enableDebug(bot: *Bot, value: bool) void {
    bot.apiClient.debug = value;
}

pub fn getUpdates(bot: *Bot, allocator: std.mem.Allocator) !?Updates {
    return try Updates.fetchAll(allocator, bot.apiClient, &bot.lastUpdateId);
}

const InitError = error{Error};

pub fn init(allocator: std.mem.Allocator, token: []const u8) !*Bot {
    assert(token.len > 0);

    var bot = try allocator.create(Bot);
    errdefer allocator.destroy(bot);

    bot.allocator = allocator;
    bot.apiClient = try ApiClient.init(allocator, token);
    errdefer bot.apiClient.deinit();

    // getMe as status check
    var getMeHolder = try bot.apiClient.request(allocator, "getMe", GetMeObject) orelse {
        std.debug.panic("/getMe returned null\n", .{});
    };
    defer getMeHolder.deinit();

    return bot;
}

pub fn deinit(bot: *Bot) void {
    bot.apiClient.deinit();
    bot.allocator.destroy(bot);
}

const GetMeObject = struct {
    id: u64,
    is_bot: bool,
    first_name: []const u8,
    username: []const u8,
    can_join_groups: bool,
    can_read_all_group_messages: bool,
    supports_inline_queries: bool,
};
