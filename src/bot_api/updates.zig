const std = @import("std");
const Allocator = std.mem.Allocator;
const Message = @import("message.zig");
const Update = @import("update.zig");
const ApiClient = @import("api_client.zig");

const Updates = @This();

source: ApiClient.ObjectHolder([]Update),

pub fn deinit(updates: *Updates) void {
    updates.source.deinit();
}

pub fn fetchAll(allocator: Allocator, apiClient: *ApiClient, lastUpdateId: *u32) !?Updates {
    var url = try std.fmt.allocPrint(allocator, "getUpdates?offset={d}", .{lastUpdateId.*});
    defer allocator.free(url);

    var updatesHolder = try apiClient.request(allocator, url, []Update) orelse return null;
    errdefer updatesHolder.deinit();

    var maxId: u32 = 0;
    var updatesSlice = updatesHolder.get();
    for (updatesSlice.*) |*update| {
        if (update.update_id > maxId) {
            maxId = update.update_id;
        }
    }

    if (maxId > 0) {
        lastUpdateId.* = maxId + 1;
    }

    return Updates{
        .source = updatesHolder,
    };
}

pub inline fn getSlice(updates: *Updates) []Update {
    return updates.source.get().*;
}
