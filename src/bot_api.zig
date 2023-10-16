const std = @import("std");
const log = std.log;
const zhttp = @import("zhttp.zig");
const Bot = @This();

allocator: std.mem.Allocator,
token: []const u8,
debug: bool = false,

const API_URL = "https://api.telegram.org/bot";

inline fn urlForMethod(allocator: std.mem.Allocator, token: []const u8, method: []const u8) []const u8 {
    return std.fmt.allocPrint(allocator, "{s}{s}/{s}", .{ API_URL, token, method }) catch unreachable;
}

pub fn request(bot: *Bot, method: []const u8, comptime T: type) !zhttp.Response(T) {
    var jsonClient = zhttp.HttpJsonClient.init(bot.allocator);
    defer jsonClient.deinit();

    try jsonClient.appendHeader("accept", "application/json");

    var url = urlForMethod(bot.allocator, bot.token, method);
    defer bot.allocator.free(url);

    return try jsonClient.request(.GET, url, T);
}
