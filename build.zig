const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const linkage = b.option(std.builtin.LinkMode, "linkage", "Specify static or dynamic linkage") orelse .dynamic;
    const upstream = b.dependency("rcutils", .{});
    var lib = std.Build.Step.Compile.create(b, .{
        .root_module = .{
            .target = target,
            .optimize = optimize,
        },
        .name = "rcutils",
        .kind = .lib,
        .linkage = linkage,
    });

    const python_command =
        \\import em
        \\em.invoke(['-o', 'include/rcutils/logging_macros.h', '-D', 'rcutils_module_path="./"', 'resource/logging_macros.h.em'])
    ;

    var python_step = b.addSystemCommand(&.{ "python3", "-c", python_command });
    python_step.setCwd(upstream.path(""));

    lib.step.dependOn(&python_step.step);

    lib.linkLibC();
    lib.addIncludePath(upstream.path("include"));

    const time = switch (target.result.os.tag) {
        .windows => "src/time_win32.c",
        else => "src/time_unix.c",
    };
    lib.addCSourceFiles(.{
        .root = upstream.path(""),
        .files = &.{
            "src/allocator.c",
            "src/array_list.c",
            "src/char_array.c",
            "src/cmdline_parser.c",
            "src/env.c",
            "src/error_handling.c",
            "src/filesystem.c",
            "src/find.c",
            "src/format_string.c",
            "src/hash_map.c",
            "src/logging.c",
            "src/qsort.c",
            "src/repl_str.c",
            "src/sha256.c",
            "src/shared_library.c",
            "src/snprintf.c",
            "src/split.c",
            "src/strcasecmp.c",
            "src/strdup.c",
            "src/strerror.c",
            "src/string_array.c",
            "src/string_map.c",
            "src/time.c",
            time,
            "src/uint8_array.c",
        },
    });

    // process.c assumes that program_invocation_name exists which is a gnu specific thing.
    // musl optionally supports this if the _GNU_SOURCE is specified,
    // however when enabling this across the board,
    // rcutils strerror.c tries to use the gnu version of strerror_r which musl doesn't seem to support.
    // To get around this, we define _GNU_SOURCE only for process.c
    lib.addCSourceFiles(.{
        .root = upstream.path(""),
        .files = &.{
            "src/process.c",
        },
        .flags = &[_][]const u8{"-D_GNU_SOURCE"},
    });

    lib.installHeadersDirectory(
        upstream.path("include"),
        "",
        .{},
    );
    b.installArtifact(lib);

    // Export python logging.py
    var python = b.addNamedWriteFiles("rcutils");
    _ = python.addCopyDirectory(
        upstream.path("rcutils"),
        "rcutils",
        .{ .exclude_extensions = &.{ "__pycache__", ".pyc" } },
    );
    b.installDirectory(.{
        .source_dir = python.getDirectory(),
        .install_dir = .{ .custom = "" },
        .install_subdir = "",
    });
}
