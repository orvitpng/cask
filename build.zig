const std = @import("std");
const builtin = @import("builtin");

const targets: Targets() = @import("targets.zon");

pub fn build(b: *std.Build) !void {
    const Type = @TypeOf(targets);
    inline for (@typeInfo(Type).@"struct".fields) |field| {
        const target = @field(targets, field.name);
        build_target(b, field.name, target);
    }
}

fn build_target(
    b: *std.Build,
    comptime name: []const u8,
    comptime target: anytype,
) void {
    const create = std.Build.Module.CreateOptions{
        .optimize = switch (b.release_mode) {
            .fast => .ReleaseFast,
            .safe => .ReleaseSafe,
            .small => .ReleaseSmall,
            else => .Debug,
        },
        .target = target.resolved(),
        .code_model = target.target.model,
        .unwind_tables = .none,
    };

    const module = b.createModule(create);
    const files = b.path(target.files.path);
    const include = files.path(b, "include");

    {
        const mod = b.createModule(create);
        mod.addIncludePath(include);

        for (target.files.head) |file|
            mod.addAssemblyFile(files.path(b, file));

        const obj = b.addObject(.{
            .name = "head",
            .root_module = mod,
        });

        module.addObject(obj);
        install(b, name, obj);
    }

    {
        const mod = b.createModule(create);
        mod.addIncludePath(include);

        for (target.files.boot) |file|
            mod.addAssemblyFile(files.path(b, file));

        const obj = b.addObject(.{
            .name = "boot",
            .root_module = mod,
        });

        module.addObject(obj);
        install(b, name, obj);
    }

    {
        const opts = merge(create, .{
            .root_source_file = b.path("init/main.zig"),
        });

        const obj = b.addObject(.{
            .name = "init",
            .root_module = b.createModule(opts),
        });

        module.addObject(obj);
        install(b, name, obj);
    }

    const exe = b.addExecutable(.{ .name = "kernel", .root_module = module });
    exe.setLinkerScript(b.path("link.ld"));

    const copy = b.addObjCopy(exe.getEmittedBin(), .{ .format = .bin });
    const i = b.addInstallBinFile(copy.getOutput(), name);
    b.getInstallStep().dependOn(&i.step);

    install(b, name, exe);
}

fn install(
    b: *std.Build,
    comptime name: []const u8,
    artifact: *std.Build.Step.Compile,
) void {
    const i = b.addInstallArtifact(
        artifact,
        .{ .dest_dir = .{ .override = .{ .custom = name } } },
    );

    b.getInstallStep().dependOn(&i.step);
}

fn merge(base: anytype, ovrds: Overrides(@TypeOf(base))) @TypeOf(base) {
    const Base = @TypeOf(base);

    var opts = base;
    inline for (@typeInfo(Base).@"struct".fields) |field|
        if (@field(ovrds, field.name)) |val| {
            @field(&opts, field.name) = val;
        };

    return opts;
}

fn Targets() type {
    const zon = @import("targets.zon");
    const Zon = @TypeOf(zon);

    const info = @typeInfo(Zon).@"struct";
    var names: [info.fields.len][]const u8 = undefined;
    var types: [info.fields.len]type = undefined;
    var attrs: [info.fields.len]std.builtin.Type.StructField.Attributes =
        undefined;

    inline for (info.fields, 0..) |field, i| {
        const name = @field(zon, field.name).target.cpu.arch;
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

fn Target(comptime arch: std.Target.Cpu.Arch) type {
    const family = @field(std.Target, @tagName(arch.family()));

    return struct {
        target: struct {
            cpu: struct {
                arch: std.Target.Cpu.Arch,
                feats: []const family.Feature,
            },
            model: std.builtin.CodeModel,
        },
        files: struct {
            path: []const u8,
            head: []const []const u8,
            boot: []const []const u8,
        },

        pub fn resolved(self: @This()) std.Build.ResolvedTarget {
            const target = std.Target{
                .cpu = .{
                    .arch = arch,
                    .model = &family.cpu.generic,
                    .features = family.featureSet(self.target.cpu.feats),
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

fn Overrides(comptime T: type) type {
    const info = @typeInfo(T).@"struct";
    var names: [info.fields.len][]const u8 = undefined;
    var types: [info.fields.len]type = undefined;
    var attrs: [info.fields.len]std.builtin.Type.StructField.Attributes =
        undefined;

    for (info.fields, 0..) |field, i| {
        const val: ?field.type = null;
        names[i] = field.name;
        types[i] = ?field.type;
        attrs[i] = .{ .default_value_ptr = @ptrCast(&val) };
    }

    return @Struct(.auto, null, &names, &types, &attrs);
}
