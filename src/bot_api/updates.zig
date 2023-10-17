const std = @import("std");
const Allocator = std.mem.Allocator;
const Message = @import("message.zig");
const ApiClient = @import("api_client.zig");
const Updates = @This();


source: ApiClient.ObjectHolder([]Object),


pub fn deinit(updates: *Updates) void {
    updates.source.deinit();
}

pub fn fetchAll(allocator: Allocator, apiClient: *ApiClient, lastUpdateId: *u64) !Updates {
    var url = try std.fmt.allocPrint(
        allocator, "getUpdates?offset={d}", 
        .{lastUpdateId.*}
    );
    defer allocator.free(url);

    var updatesHolder = try apiClient.request(allocator, url, []Object);
    errdefer updatesHolder.deinit();

    var maxId: u64 = 0;
    var updatesSlice = updatesHolder.get();
    for (updatesSlice.*) |update| {
        if (update.update_id > maxId) {
            maxId = update.update_id;
        }
    }

    if (maxId > 0) {
        lastUpdateId.* = maxId + 1;
    }

    // std.debug.print("RAW: {s}\n\n", .{updatesResp.rawBody});
    return Updates {
        .source = updatesHolder,
    };
}

pub inline fn getSlice(updates: *Updates) []Object {
    return updates.source.get().*;
}

const Object = struct {
    update_id: u64,
    message: ?Message.Object,
};