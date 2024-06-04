const ziglua = @import("ziglua");
const clap = @import("clap");
const std = @import("std");

const debug = std.debug;
const io = std.io;

const Lua = ziglua.Lua;

const description = (
    \\
    \\devl: a dev shell utility
    \\Version: 0.0.1
    \\
    \\
);

const default_devl_lua_filename = "./" ++ std.fs.path.sep_str ++ ".devl.lua";

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout_file = std.io.getStdOut().writer();
    var stdout_buffer = std.io.bufferedWriter(stdout_file);
    const stdout = stdout_buffer.writer();

    try stdout.print("Running devl...\n", .{});

    // >>> ARG PARSING

    const params = comptime clap.parseParamsComptime(
        \\-h, --help        Display this help and exit
        \\-c, --config <str>  path to a devl config lua file [default: ./.devl.lua]
        \\<str>
        \\
    );

    // init diagnostics
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = allocator,
    }) catch |err| {
        diag.report(io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    // TODO: Parse args into a struct
    if (res.args.help != 0) {
        const writer = io.getStdErr().writer();
        try writer.writeAll(description);
        return clap.help(writer, clap.Help, &params, .{});
    }
    const devl_config_filename = res.args.config orelse default_devl_lua_filename;
    for (res.positionals, 0..) |p, i| debug.print("positional_{} = {s}\n", .{ i, p });

    // >>> READ LUA CONFIG

    var lua = try Lua.init(&allocator);
    defer lua.deinit();

    try lua.doFile(@ptrCast(devl_config_filename));
    lua.setGlobal("config");
    lua.setTop(0);

    _ = try lua.getGlobal("config");
    _ = lua.getField(-1, "project_name");
    const foo = try lua.toString(-1);

    std.debug.print("project_name = {s}\n", .{foo});
}
