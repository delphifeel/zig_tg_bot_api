const std = @import("std");
const log = std.log;

pub fn Response(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        rawBody: []const u8,
        body: T,
        ok: bool,

        pub fn deinit(self: @This()) void {
            self.allocator.free(self.rawBody);
        }
    };
}

pub const HttpJsonClient = struct {
    allocator: std.mem.Allocator,
    client: std.http.Client,
    headers: std.http.Headers,
    RESPONSE_MAX_SIZE: u32 = 16184,

    pub fn init(allocator: std.mem.Allocator) HttpJsonClient {
        return HttpJsonClient{
            .allocator = allocator,
            .headers = std.http.Headers.init(allocator),
            .client = std.http.Client{ .allocator = allocator },
        };
    }

    pub fn deinit(self: *HttpJsonClient) void {
        self.headers.deinit();
        self.client.deinit();
    }

    pub fn appendHeader(self: *HttpJsonClient, name: []const u8, value: []const u8) !void {
        try self.headers.append(name, value);
    }

    pub fn request(self: *HttpJsonClient, method: std.http.Method, url: []const u8, comptime T: type) !Response(T) {
        var uri = std.Uri.parse(url) catch unreachable;

        var req = try self.client.request(method, uri, self.headers, .{});
        defer req.deinit();
        try req.start(.{});
        try req.wait();

        var body = try req.reader().readAllAlloc(self.allocator, self.RESPONSE_MAX_SIZE);

        var parseOptions = std.json.ParseOptions{
            .ignore_unknown_fields = true,
            .allocate = .alloc_if_needed,
        };
        var parsedJson = try std.json.parseFromSlice(T, self.allocator, body, parseOptions);
        defer parsedJson.deinit();
        return Response(T){
            .allocator = self.allocator,
            .rawBody = body,
            .ok = req.response.status == .ok,
            .body = parsedJson.value,
        };
    }
};
