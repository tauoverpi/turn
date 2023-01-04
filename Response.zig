const std = @import("std");
const math = std.math;

const Response = @This();

curve: Curve,
type: Response.Type,

pub const Type = enum {
    logistic,
    logit,
    bezier,
    normal,
    constant,
};

pub fn y(self: Response, x: f32) f32 {
    return self.curve.y(self.type, x);
}

pub const Curve = struct {
    m: f32,
    k: f32,
    c: f32,
    b: f32,

    pub fn y(self: Curve, typ: Type, x: f32) f32 {
        return switch (typ) {
            .constant => x,
            inline else => |name| @field(self, @tagName(name))(x),
        };
    }

    pub fn logistic(self: Curve, x: f32) f32 {
        const m = self.m;
        const k = self.k;
        const c = self.c;
        const b = self.b;
        return math.clamp(
            m / (1 + @exp(k * (x - c))) + b,
            0,
            1,
        );
    }

    pub fn logit(self: Curve, x: f32) f32 {
        const m = self.m;
        const c = self.c;
        const b = self.b;
        return math.clamp(
            m * math.log10((x - c) / (1.0 - (x - c))) / 5.0 + 0.5 + b,
            0,
            1,
        );
    }

    pub fn bezier(self: Curve, x: f32) f32 {
        const a = self.m;
        const b = self.c;
        const c = self.b;
        const d = self.k;
        const @"(1-x)^3" = (1 - x) * (1 - x) * (1 - x);
        const @"3x(1-x)^2" = 3 * x * (1 - x) * (1 - x);
        const @"3x^2(1-x)" = 3 * x * x * (1 - x);
        const @"x^3" = x * x * x;
        return math.clamp(
            a * @"(1-x)^3" + b * @"3x(1-x)^2" + c * @"3x^2(1-x)" + d * @"x^3",
            0,
            1,
        );
    }

    pub fn normal(self: Curve, x: f32) f32 {
        const m = self.m;
        const k = self.k;
        const c = self.c;
        const b = self.b;
        return math.clamp(
            m * @exp(-30.0 * k * math.pow(f32, x - c - 0.5, 2)) + b,
            0,
            1,
        );
    }
};
