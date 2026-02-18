const std = @import("std");
const builtin = @import("builtin");

const targets: Targets = @import("build/targets.zon");

const helpers = @import("build/helpers.zig");

const Options = helpers.Overrides(std.Build.Module.CreateOptions);

pub fn build(b: *std.Build) !void {
    const optimize =
        b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSafe });

    const arch = b.option(
        []const u8,
        "arch",
        "Target architecture (or \"all\")",
    ) orelse @tagName(builtin.cpu.arch);

    if (!std.mem.eql(u8, arch, "all")) {
        inline for (@typeInfo(Targets).@"struct".fields) |field|
            if (std.mem.eql(u8, arch, field.name))
                return @field(targets, field.name).build(b, optimize);
        return error.UnsupportedArch;
    }

    inline for (@typeInfo(Targets).@"struct".fields) |field|
        @field(targets, field.name).build(b, optimize);
}

// TODO: allow it to be called whatever and contain its own arch
fn Target(arch: std.Target.Cpu.Arch) type {
    const family = @field(std.Target, @tagName(arch.family()));

    return struct {
        const Self = @This();

        cpu: struct {
            arch: std.Target.Cpu.Arch,
            features: []const family.Feature,
        },
        arch: struct {
            name: []const u8,
            boot: []const []const u8,
        },

        pub fn build(
            comptime self: @This(),
            b: *std.Build,
            optimize: std.builtin.OptimizeMode,
        ) void {
            const ctx = Context{
                .b = b,
                .arch = b.path("arch/" ++ self.arch.name),
                .opts = .{
                    .target = self.resolved(),
                    .optimize = optimize,
                },
            };

            const exe = b.addExecutable(.{
                .name = "kernel",
                .root_module = b.createModule(ctx.opts),
            });

            exe.addObject(self.boot(ctx));
            exe.setLinkerScript(b.path("link.ld"));

            b.installArtifact(exe);

            const bin = exe.addObjCopy(.{ .format = .bin });
            const i =
                b.addInstallFile(bin.getOutput(), @tagName(self.cpu.arch));
            b.getInstallStep().dependOn(&i.step);
        }

        fn boot(comptime self: Self, ctx: Context) *std.Build.Step.Compile {
            const obj = ctx.b.addObject(.{
                .name = "boot",
                .root_module = ctx.b.createModule(ctx.opts),
            });

            inline for (self.arch.boot) |file|
                obj.addAssemblyFile(ctx.arch.path(ctx.b, "boot/" ++ file));
            obj.setLinkerScript(ctx.b.path("boot/link.ld"));

            return obj;
        }

        fn resolved(comptime self: Self) std.Build.ResolvedTarget {
            const t = self.target();
            return .{
                .query = .fromTarget(&t),
                .result = t,
            };
        }

        fn target(comptime self: Self) std.Target {
            return .{
                .abi = .none,
                .ofmt = .elf,
                .cpu = .{
                    .arch = arch,
                    .model = &family.cpu.generic,
                    .features = family.featureSet(self.cpu.features),
                },
                .os = .{
                    .tag = .freestanding,
                    .version_range = .{ .none = {} },
                },
            };
        }
    };
}

const Context = struct {
    b: *std.Build,
    arch: std.Build.LazyPath,
    opts: std.Build.Module.CreateOptions,
};

const Targets = blk: {
    const zon = @import("build/targets.zon");
    const Zon = @TypeOf(zon);

    const info = @typeInfo(Zon).@"struct";
    var fields: [info.fields.len]std.builtin.Type.StructField = undefined;
    for (info.fields, 0..) |field, i| {
        const arch = std.meta.stringToEnum(
            std.Target.Cpu.Arch,
            field.name,
        ) orelse @compileError("unknown arch");
        const Type = Target(arch);

        fields[i] = .{
            .type = Type,
            .name = field.name,
            .default_value_ptr = null,
            .is_comptime = false,
            .alignment = @alignOf(Type),
        };
    }

    break :blk @Type(.{ .@"struct" = .{
        .layout = .auto,
        .is_tuple = false,
        .fields = &fields,
        .decls = &.{},
    } });
};
