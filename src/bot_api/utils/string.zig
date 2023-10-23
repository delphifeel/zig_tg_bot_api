const std = @import("std");

pub const string = []const u8;

pub fn stringEq(a: string, b: string) bool {
    return std.mem.eql(u8, a, b);
}
