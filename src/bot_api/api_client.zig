const std = @import("std");
const http = @import("http.zig");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const ApiClient = @This();

allocator: Allocator,
token: []const u8,
debug: bool,
json_client: *http.HttpJsonClient,

pub fn init(allocator: std.mem.Allocator, token: []const u8) !*ApiClient {
    var api_client = try allocator.create(ApiClient);
    errdefer allocator.destroy(api_client);

    api_client.allocator = allocator;
    api_client.token = token;
    api_client.debug = false;
    api_client.json_client = try http.HttpJsonClient.init(allocator);
    errdefer api_client.json_client.deinit();

    return api_client;
}

pub fn deinit(api_client: *ApiClient) void {
    api_client.json_client.deinit();
    api_client.allocator.destroy(api_client);
}

pub fn request(api_client: *ApiClient, allocator: Allocator, method: []const u8, comptime T: type) !?ObjectHolder(T) {
    try api_client.json_client.appendHeader("accept", "application/json");

    var url = urlForMethod(allocator, api_client.token, method);
    defer allocator.free(url);

    var jsonResp = try api_client.json_client.request(.GET, url, TgBotResult(T)) orelse return null;
    errdefer jsonResp.deinit();
    var tgBotResp = jsonResp.body();
    if (!tgBotResp.ok) {
        return null;
    }
    return ObjectHolder(T).init(jsonResp);
}

pub fn ObjectHolder(comptime T: type) type {
    return struct {
        const Self = @This();

        source: http.Response(TgBotResult(T)),

        pub fn init(source: http.Response(TgBotResult(T))) Self {
            return Self{
                .source = source,
            };
        }

        pub inline fn deinit(self: *Self) void {
            self.source.deinit();
        }

        pub inline fn get(self: *Self) *T {
            return &self.source.body().result;
        }
    };
}

const API_URL = "https://api.telegram.org/bot";

inline fn urlForMethod(allocator: std.mem.Allocator, token: []const u8, method: []const u8) []const u8 {
    return std.fmt.allocPrint(allocator, "{s}{s}/{s}", .{ API_URL, token, method }) catch unreachable;
}

fn TgBotResult(comptime T: type) type {
    return struct {
        ok: bool,
        result: T,
    };
}
