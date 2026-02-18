const std = @import("std");

pub fn merge(base: anytype, ovrds: Overrides(@TypeOf(base))) @TypeOf(base) {
    const Type = @TypeOf(base);

    var opts = base;
    inline for (@typeInfo(Type).@"struct".fields) |field|
        if (@field(ovrds, field.name)) |val| {
            @field(&opts, field.name) = val;
        };

    return opts;
}

pub fn Overrides(comptime T: type) type {
    const info = @typeInfo(T).@"struct";

    var fields: [info.fields.len]std.builtin.Type.StructField = undefined;
    for (info.fields, 0..) |field, i| {
        const val: ?field.type = null;
        fields[i] = .{
            .name = field.name,
            .type = ?field.type,
            .default_value_ptr = @ptrCast(&val),
            .is_comptime = false,
            .alignment = @alignOf(?field.type),
        };
    }

    return @Type(.{ .@"struct" = .{
        .layout = .auto,
        .is_tuple = false,
        .fields = &fields,
        .decls = &.{},
    } });
}
