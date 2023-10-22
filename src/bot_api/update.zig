const Message = @import("message.zig");

const Update = @This();

update_id: u32,
message: ?Message,

pub inline fn getMessage(update: *Update) ?*Message {
    if (update.message) |*msg| {
        return msg;
    }
    return null;
}
