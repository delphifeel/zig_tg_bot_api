const std = @import("std");
const Allocator = std.mem.Allocator;

/// create T and copy from source
pub fn createFrom(allocator: Allocator, comptime T: type, source: *const T) !*T {
    var result = try allocator.create(T);
    result.* = source.*;
    return result;
}
