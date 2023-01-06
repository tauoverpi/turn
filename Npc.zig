const std = @import("std");
const game = @import("game.zig");
const assert = std.debug.assert;

const Npc = @This();
const Weapon = game.Weapon;
const Affinity = game.Affinity;
const Gear = game.Gear;
const Armour = game.Armour;
const Utility = game.Utility;

health: f32 = 100,
health_max: f32 = 100,

magic: f32 = 100,
magic_max: f32 = 100,
magic_strength: f32 = 0,
magic_resistance: f32 = 0,

fire_resistance: f32 = 1,
cold_resistance: f32 = 1,
electricity_resistance: f32 = 1,
gravity_resistance: f32 = 1,
dark_resistance: f32 = 1,
light_resistance: f32 = 1,
chaos_resistance: f32 = 1,

weapon: Weapon = .none,
gear: [2]Gear = .{ .none, .none },
armour: Armour = .none,
affinity: Affinity = .{},

attack: f32 = 100,
attack_max: f32 = 100,
attack_strength: f32 = 1,
attack_resistance: f32 = 1,

// xp_knowledge: f32 = 0,
// xp_combat: f32 = 0,
// status_effect: Status,

queue: f32 = 100,
luck: f32 = 0.01, // clamped at 0.2
crit: f32 = 0.01,

pub fn signal(self: Npc, typ: Utility.Motive.Resource.Type) f32 {
    return switch (typ) {
        .health => self.health / self.health_max,
        .magic => self.magic / self.magic_max,
        .attack => self.attack / self.attack_max,

        .fire_affinity,
        .cold_affinity,
        .electricity_affinity,
        .gravity_affinity,
        .dark_affinity,
        .light_affinity,
        .chaos_affinity,
        => |name| self.affinity.signal(@intToEnum(Affinity.Type, @enumToInt(name))),

        inline //
        .fire_resistance,
        .cold_resistance,
        .electricity_resistance,
        .gravity_resistance,
        .dark_resistance,
        .light_resistance,
        .chaos_resistance,
        => |name| @field(self, @tagName(name)),

        inline else => |name| @field(self, @tagName(name)),
    };
}
