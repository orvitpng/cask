const std = @import("std");
const builtin = @import("builtin");

const Targets = Type();
const targets: Targets = @import("build/targets.zon");

pub fn build(b: *std.Build) !void {
    inline for (@typeInfo(Targets).@"struct".fields) |field| {
        const target = @field(targets, field.name);
        build_target(b, field.name, target);
    }
}

fn build_target(
    b: *std.Build,
    comptime name: []const u8,
    comptime target: anytype,
) void {
    const files = b.path(target.files.path);
    const opts = std.Build.Module.CreateOptions{
        .target = target.resolved(),
        .optimize = switch (b.release_mode) {
            .fast => .ReleaseFast,
            .safe => .ReleaseSafe,
            .small => .ReleaseSmall,
            else => .Debug,
        },
    };

    const mod = b.createModule(opts);
    inline for (target.files.boot) |file|
        mod.addAssemblyFile(files.path(b, file));

    const exe = b.addExecutable(.{ .name = "kernel", .root_module = mod });
    exe.setLinkerScript(b.path("build/link.ld"));

    const obj = exe.getEmittedBin();
    const copy = b.addObjCopy(obj, .{ .format = .bin });

    const elf = b.addInstallBinFile(obj, name ++ ".elf");
    const bin = b.addInstallFile(copy.getOutput(), name);
    bin.step.dependOn(&elf.step);

    b.getInstallStep().dependOn(&bin.step);
}

fn Target(comptime arch: std.Target.Cpu.Arch) type {
    const family = @field(std.Target, @tagName(arch.family()));

    return struct {
        arch: std.Target.Cpu.Arch,
        features: []const family.Feature,
        files: struct {
            path: []const u8,
            boot: []const []const u8,
        },

        pub fn resolved(self: @This()) std.Build.ResolvedTarget {
            const target = std.Target{
                .cpu = .{
                    .arch = self.arch,
                    .model = &family.cpu.generic,
                    .features = family.featureSet(self.features),
                },
                .os = .{
                    .tag = .freestanding,
                    .version_range = .{ .none = {} },
                },
                .abi = .none,
                .ofmt = .elf,
            };

            return .{
                .query = .fromTarget(&target),
                .result = target,
            };
        }
    };
}

fn Type() type {
    const zon = @import("build/targets.zon");
    const Zon = @TypeOf(zon);

    const info = @typeInfo(Zon).@"struct";
    var names: [info.fields.len][]const u8 = undefined;
    var types: [info.fields.len]type = undefined;
    var attrs: [info.fields.len]std.builtin.Type.StructField.Attributes =
        undefined;

    inline for (info.fields, 0..) |field, i| {
        const name = @field(zon, field.name).arch;
        const arch = std.meta.stringToEnum(
            std.Target.Cpu.Arch,
            @tagName(name),
        ).?;

        names[i] = field.name;
        types[i] = Target(arch);
        attrs[i] = .{};
    }

    return @Struct(.auto, null, &names, &types, &attrs);
}
