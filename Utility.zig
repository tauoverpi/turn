const std = @import("std");
const meta = @import("meta.zig");
const math = std.math;
const testing = std.testing;

const ArrayList = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;
const Npc = @import("game.zig").Npc;
const Utility = @This();

motive: ArrayList(Motive) = .{},
sorted: bool = false,

pub fn deinit(self: *Utility, gpa: Allocator) void {
    self.motive.deinit(gpa);
    self.* = undefined;
}

pub fn append(self: *Utility, gpa: Allocator, motive: Motive) error{OutOfMemory}!void {
    errdefer self.sorted = true;
    self.sorted = false;

    try self.motive.append(gpa, motive);
}

pub fn remove(self: *Utility, index: usize) void {
    if (self.motive.items.len != index + 1) self.sorted = false;
    _ = self.motive.swapRemove(index);
}

fn sort(self: *Utility) void {
    if (!self.sorted) {
        std.sort.sort(Motive, self.motive.items, {}, struct {
            pub fn lessThan(_: void, lhs: Motive, rhs: Motive) bool {
                const l_name = @enumToInt(lhs.action.name);
                const r_name = @enumToInt(rhs.action.name);
                const l_type = @enumToInt(lhs.action.type);
                const r_type = @enumToInt(rhs.action.type);
                const l_target = lhs.action.target;
                const r_target = rhs.action.target;

                return l_name < r_name or
                    (l_name == r_name and l_target < r_target) or
                    (l_name == r_name and l_target == r_target and l_type < r_type);
            }
        }.lessThan);
        self.sorted = true;
    }
}

pub fn select(self: *Utility, me: Npc, them: []const Npc) Motive.Action {
    var it = self.iterate();

    var max: f32 = 0;
    var min: f32 = 0;
    var act: ?Motive.Action = null;

    for (them) |foe| {
        loop: while (it.next()) |action| {
            const modification: f32 = 1 - (1 / @intToFloat(f32, action.len));

            var total: f32 = 1;

            for (action) |motive| {
                if (total < min) continue :loop;

                const con = motive.response.y(switch (motive.resource.target) {
                    .me => me.signal(motive.resource.type),
                    .them => foe.signal(motive.resource.type),
                });

                total *= math.clamp(con + (1 - con) * con * modification, 0, 1);
            }

            if (total > max) {
                act = action[0].action;
                max = total;
            }
        }
    }

    return act.?;
}

test "select" {
    var u: Utility = .{};
    defer u.deinit(testing.allocator);

    try u.testSetup(testing.allocator);

    _ = u.select(.{}, &.{.{}});
}

pub fn iterate(self: *Utility) Iterator {
    self.sort();

    return .{ .items = self.motive.items };
}

fn testSetup(self: *Utility, gpa: Allocator) !void {
    try self.append(gpa, .{
        .resource = .{ .target = .me, .type = .magic },
        .response = .{ .curve = undefined, .type = .constant },
        .action = .{ .name = .slash, .target = 1 },
    });

    try self.append(gpa, .{
        .resource = .{ .target = .me, .type = .magic },
        .response = .{ .curve = undefined, .type = .constant },
        .action = .{ .name = .slash, .target = 0 },
    });

    try self.append(gpa, .{
        .resource = .{ .target = .them, .type = .health },
        .response = .{ .curve = undefined, .type = .constant },
        .action = .{ .name = .slash, .target = 0, .type = .expensive },
    });

    try self.append(gpa, .{
        .resource = .{ .target = .me, .type = .crit },
        .response = .{ .curve = undefined, .type = .constant },
        .action = .{ .name = .slash, .target = 0, .type = .eliminator },
    });
}

test "iterate" {
    var u: Utility = .{};
    defer u.deinit(testing.allocator);

    try u.testSetup(testing.allocator);

    var it = u.iterate();

    const result = it.next().?;
    try testing.expectEqual(@as(usize, 3), result.len);

    const Type = Motive.Action.Type;
    try testing.expectEqual(Type.eliminator, result[0].action.type);
    try testing.expectEqual(Type.normal, result[1].action.type);
    try testing.expectEqual(Type.expensive, result[2].action.type);

    try testing.expectEqual(@as(usize, 1), it.next().?.len);

    try testing.expect(it.next() == null);
}

pub const Iterator = struct {
    items: []const Motive,
    index: usize = 0,

    pub fn next(self: *Iterator) ?[]const Motive {
        const start = self.index;
        if (start >= self.items.len) return null;

        const action = self.items[start].action;
        for (self.items[start + 1 ..]) |item| {
            self.index += 1;
            const cond = //
                item.action.name != action.name or
                item.action.target != action.target;
            if (cond) break;
        } else {
            self.index += 1;
        }

        return self.items[start..self.index];
    }
};

pub const Motive = struct {
    resource: Resource,
    response: Response,
    action: Action,

    pub const Action = packed struct(u16) {
        name: Name,
        target: u6,
        type: Type = .normal,

        pub const Type = enum(u2) {
            /// Likely to short-circuit
            eliminator,
            /// Inexpensive to compute
            cheap,
            /// No particular order
            normal,
            /// Expensive to compute and thus should be considered last
            expensive,
        };

        pub const Name = enum(u8) {
            slash,
            stab,
        };
    };

    pub const Resource = packed struct(u16) {
        target: Target,
        type: Type,

        pub const Target = enum(u1) {
            me,
            them,
        };

        pub const Type = enum(u15) {
            fire_affinity,
            cold_affinity,
            electricity_affinity,
            gravity_affinity,
            dark_affinity,
            light_affinity,
            chaos_affinity,
            fire_resistance,
            cold_resistance,
            electricity_resistance,
            gravity_resistance,
            dark_resistance,
            light_resistance,
            chaos_resistance,
            attack,
            magic,
            health,
            luck,
            crit,
            queue,
        };
    };

    pub const Response = @import("Response.zig");
};
