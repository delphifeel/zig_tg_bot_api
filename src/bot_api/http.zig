const std = @import("std");
const utils = @import("utils.zig");

pub fn Response(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        parsedJson: *std.json.Parsed(T),

        pub fn init(allocator: std.mem.Allocator, parsedJson: *std.json.Parsed(T)) !Self {
            var jsonCopy = try utils.createFrom(allocator, std.json.Parsed(T), parsedJson);
            return Response(T){
                .allocator = allocator,
                .parsedJson = jsonCopy,
            };
        }

        pub fn deinit(self: *Self) void {
            self.parsedJson.deinit();
            self.allocator.destroy(self.parsedJson);
        }

        pub inline fn body(self: *const Self) T {
            return self.parsedJson.value;
        }
    };
}

pub const HttpJsonClient = struct {
    allocator: std.mem.Allocator,
    client: std.http.Client,
    headers: std.http.Headers,
    responseMaxSize: u32 = 120000,

    pub fn init(allocator: std.mem.Allocator) !*HttpJsonClient {
        var inited = HttpJsonClient{
            .allocator = allocator,
            .headers = std.http.Headers.init(allocator),
            .client = std.http.Client{ .allocator = allocator },
        };
        return try utils.createFrom(allocator, HttpJsonClient, &inited);
    }

    pub fn deinit(self: *HttpJsonClient) void {
        self.headers.deinit();
        self.client.deinit();
        self.allocator.destroy(self);
    }

    pub fn appendHeader(self: *HttpJsonClient, name: []const u8, value: []const u8) !void {
        try self.headers.append(name, value);
    }

    pub fn request(self: *HttpJsonClient, method: std.http.Method, url: []const u8, comptime T: type) !Response(T) {
        var uri = try std.Uri.parse(url);

        var req = try self.client.request(method, uri, self.headers, .{});
        defer req.deinit();
        try req.start(.{});
        // try req.start();
        try req.wait();
        if (req.response.status != .ok) {
            unreachable;
        }

        var body = try req.reader().readAllAlloc(self.allocator, self.responseMaxSize);
        defer self.allocator.free(body);

        var parseOptions = std.json.ParseOptions{
            .ignore_unknown_fields = true,
            .allocate = .alloc_always,
        };
        var parsedJson = try std.json.parseFromSlice(T, self.allocator, body, parseOptions);
        return try Response(T).init(self.allocator, &parsedJson);
    }
};
