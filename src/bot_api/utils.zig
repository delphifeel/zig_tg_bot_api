const std = @import("std");
const Allocator = std.mem.Allocator;

pub const string = []const u8;

pub fn stringEq(a: string, b: string) bool {
    return std.mem.eql(u8, a, b);
}

/// create T and copy from source
pub fn createFrom(allocator: Allocator, comptime T: type, source: *const T) !*T {
    var result = try allocator.create(T);
    result.* = source.*;
    return result;
}
