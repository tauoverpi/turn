const std = @import("std");
const math = std.math;
const testing = std.testing;
const assert = std.debug.assert;

pub const Utility = @import("Utility.zig");
pub const Affinity = @import("Affinity.zig");
pub const Npc = @import("Npc.zig");

pub const SpellClass = enum {
    /// Spells which are mostly harmless, consumes little mana.
    utility,
    /// Spells which aim to heavily injure a target, consumes moderate amounts of mana.
    defence,
    /// Spells which aim to kill a target, consumes a great deal of mana.
    attack,
    /// Spells which usually end a battle but come at a grave cost by consuming both health and mana.
    ultimate,

    pub fn cost(self: SpellClass) f32 {
        return switch (self) {
            .utility => 10,
            .defence => 15,
            .attack => 25,
            .ultimate => 80,
        };
    }
};

pub const Armour = enum {
    none,
    light,
    medium,
    heavy,
};

pub const Gear = enum {
    none,
    scarf_of_divinity,
    toe_ring_of_the_holy,
};

pub const Weapon = enum {
    none,
    /// https://en.wikipedia.org/wiki/Katana
    katana,
    /// https://en.wikipedia.org/wiki/Scimitar
    scimitar,
    /// https://en.wikipedia.org/wiki/Rapier
    rapier,
    /// https://en.wikipedia.org/wiki/Spatha
    spatha,
    /// https://en.wikipedia.org/wiki/Longsword
    longsword,
    /// https://en.wikipedia.org/wiki/Claymore
    claymore,
    /// https://en.wikipedia.org/wiki/Cutlass
    cutlass,
};
