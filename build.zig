const std = @import("std");

const arch = @import("builtin").cpu.arch;
const loader_arch: std.Target.Cpu.Arch = switch (@import("builtin").cpu.arch) {
    .x86, .x86_64 => .x86,
    else => @compileError("unsupported target"),
};

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const outputs = [_]Output{
        .{
            get_bios(b, optimize),
            "bios__" ++ @tagName(loader_arch) ++ ".bin",
        },
    };

    for (outputs) |output| {
        const step = &b.addInstallBinFile(output.@"0", output.@"1").step;
        b.getInstallStep().dependOn(step);
    }
}

pub fn get_bios(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
) std.Build.LazyPath {
    const dir = b.path("./src/loader/bios");

    const obj = b.addObject(.{
        .name = "bios",
        .target = b.resolveTargetQuery(.{ .cpu_arch = loader_arch }),
        .optimize = optimize,
    });
    obj.addAssemblyFile(dir.path(b, "main.S"));
    obj.addIncludePath(dir.path(b, @tagName(loader_arch)));
    obj.setLinkerScript(dir.path(b, "main.ld"));

    const output = obj.getEmittedBin();
    return b.addObjCopy(output, .{ .format = .bin }).getOutput();
}

const Output = struct {
    std.Build.LazyPath,
    []const u8,
};
