const std = @import("std");
const assert = std.debug.assert;
const log = std.log;
const http = @import("http.zig");
const Bot = @This();
const Updates = @import("updates.zig");
const ApiClient = @import("api_client.zig");

allocator: std.mem.Allocator,
apiClient: *ApiClient,
lastUpdateId: u64 = 0,

pub inline fn enableDebug(bot: *Bot, value: bool) void {
    bot.apiClient.debug = value;
}

pub fn getUpdates(bot: *Bot, allocator: std.mem.Allocator) !Updates {
    return try Updates.fetchAll(allocator, bot.apiClient, &bot.lastUpdateId);
}

const InitError = error {Error};

pub fn init(allocator: std.mem.Allocator, token: []const u8) !*Bot {
    assert(token.len > 0);

    var bot = try allocator.create(Bot);
    errdefer allocator.destroy(bot);

    bot.allocator = allocator;
    bot.apiClient = try ApiClient.init(allocator, token);
    errdefer bot.apiClient.deinit();

    // getMe as status check
    var getMeHolder = try bot.apiClient.request(allocator, "getMe", GetMeObject);
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