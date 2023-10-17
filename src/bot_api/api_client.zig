const std = @import("std");
const http = @import("http.zig");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const ApiClient = @This();

allocator: Allocator,
token: []const u8,
debug: bool,
jsonClient: *http.HttpJsonClient,

pub fn init(allocator: std.mem.Allocator, token: []const u8) !*ApiClient {
    var apiClient = try allocator.create(ApiClient);
    errdefer allocator.destroy(apiClient);

    apiClient.allocator = allocator;
    apiClient.token = token;
    apiClient.debug = false;
    apiClient.jsonClient = try http.HttpJsonClient.init(allocator);
    errdefer apiClient.jsonClient.deinit();

    return apiClient;
}

pub fn deinit(apiClient: *ApiClient) void {
    apiClient.jsonClient.deinit();
    apiClient.allocator.destroy(apiClient);
}

pub fn request(apiClient: *ApiClient, allocator: Allocator, method: []const u8, comptime T: type) !ObjectHolder(T) {
    try apiClient.jsonClient.appendHeader("accept", "application/json");

    var url = urlForMethod(allocator, apiClient.token, method);
    defer allocator.free(url);

    var jsonResp = try apiClient.jsonClient.request(.GET, url, TgBotResult(T));
    errdefer jsonResp.deinit();
    var tgBotResp = jsonResp.body();
    if (!tgBotResp.ok) {
        unreachable;
    }
    return try ObjectHolder(T).init(allocator, jsonResp);
}

pub fn ObjectHolder(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: Allocator,
        source: http.Response(TgBotResult(T)),
        object: *T,

        pub fn init(allocator: Allocator, source: http.Response(TgBotResult(T))) !Self {
            return Self {
                .allocator = allocator,
                .source = source,
                .object = try utils.createFrom(allocator, T, &source.body().result),
            };
        }

        pub inline fn deinit(self: *Self) void {
            self.source.deinit();
            self.allocator.destroy(self.object);
        }

        pub inline fn get(self: *Self) *T {
            return self.object;
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