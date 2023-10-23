const std = @import("std");
const utils = @import("utils.zig");
const string = utils.string;

pub fn Response(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        raw_body: string,
        parsed_json: *std.json.Parsed(T),

        pub fn init(allocator: std.mem.Allocator, parsed_json: *std.json.Parsed(T), raw_body: string) !Self {
            var jsonCopy = try utils.createFrom(allocator, std.json.Parsed(T), parsed_json);
            return Response(T){
                .allocator = allocator,
                .parsed_json = jsonCopy,
                .raw_body = raw_body,
            };
        }

        pub fn deinit(self: *Self) void {
            self.parsed_json.deinit();
            self.allocator.free(self.raw_body);
            self.allocator.destroy(self.parsed_json);
        }

        pub inline fn body(self: *Self) *T {
            return &self.parsed_json.value;
        }
    };
}

pub const HttpJsonClient = struct {
    allocator: std.mem.Allocator,
    client: std.http.Client,
    headers: std.http.Headers,
    responseMaxSize: u32 = 120000,
    debug: bool = false,

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

    pub fn request(self: *HttpJsonClient, method: std.http.Method, url: []const u8, comptime T: type) !?Response(T) {
        var uri = try std.Uri.parse(url);

        if (self.debug) {
            std.debug.print("request to {s}\n", .{url});
        }

        var req = self.client.request(method, uri, self.headers, .{}) catch return null;
        defer req.deinit();
        req.start(.{}) catch return null;
        req.wait() catch return null;
        if (req.response.status != .ok) {
            return null;
        }

        var body = try req.reader().readAllAlloc(self.allocator, self.responseMaxSize);

        var parseOptions = std.json.ParseOptions{
            .ignore_unknown_fields = true,
            .allocate = .alloc_if_needed,
        };
        var parsedJson = try std.json.parseFromSlice(T, self.allocator, body, parseOptions);
        return try Response(T).init(self.allocator, &parsedJson, body);
    }
};
