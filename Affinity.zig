const std = @import("std");
const math = std.math;
const testing = std.testing;

const Affinity = @This();

none: u10 = max_affinity,
fire: u10 = 0,
cold: u10 = 0,
electricity: u10 = 0,
gravity: u10 = 0,
dark: u10 = 0,
light: u10 = 0,
chaos: u10 = 0,

pub const max_affinity: u10 = math.maxInt(u10);

pub const Type = enum {
    fire,
    cold,
    electricity,
    gravity,
    dark,
    light,
    chaos,
};

pub fn signal(self: Affinity, typ: Type) f32 {
    switch (typ) {
        inline else => |name| {
            const value = @intToFloat(f64, @field(self, @tagName(name)));
            const fraction: f64 = 0xffff_ffff;

            return @floatCast(f32, value / fraction);
        },
    }
}

pub fn use(self: *Affinity, typ: Type, amount: u10) void {
    const fields = @typeInfo(Affinity).Struct.fields;

    var sum: u10 = 0;

    inline for (fields) |field| {
        const overflow = @subWithOverflow(@field(self, field.name), amount);
        if (overflow[1] == 0) {
            sum += amount;
            @field(self, field.name) = overflow[0];
        } else {
            sum += overflow[0] +% amount;
            @field(self, field.name) = 0;
        }
    }

    switch (typ) {
        inline else => |name| @field(self, @tagName(name)) += sum,
    }
}

test "use" {
    var aff: Affinity = .{};

    aff.use(.fire, 10);
    aff.use(.fire, 10);

    try testing.expectEqual(@as(u10, 20), aff.fire);

    aff.use(.cold, 5);

    try testing.expectEqual(@as(u10, 15), aff.fire);
    try testing.expectEqual(@as(u10, 10), aff.cold);

    aff.use(.dark, 1);

    try testing.expectEqual(@as(u10, 14), aff.fire);
    try testing.expectEqual(@as(u10, 9), aff.cold);
    try testing.expectEqual(@as(u10, 3), aff.dark);

    aff.use(.light, math.maxInt(u10));

    try testing.expectEqual(@as(u10, 0), aff.fire);
    try testing.expectEqual(@as(u10, 0), aff.cold);
    try testing.expectEqual(@as(u10, 0), aff.dark);
    try testing.expectEqual(max_affinity, aff.light);
}
