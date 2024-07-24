const clap = @import("clap");
const std = @import("std");

pub const Context = struct {
    cli_args: CliArgs,
    allocator: std.mem.Allocator,
    template_name: ?[]const u8,
    config_dir_path: []const u8,
    current_dir_path: []const u8,
    template_params: std.StringArrayHashMap([]const u8),

    pub fn init(allocator: std.mem.Allocator) !Context {
        var diagnostic = clap.Diagnostic{};
        const args = clap.parse(clap.Help, &cli_params, clap.parsers.default, .{
            .diagnostic = &diagnostic,
            .allocator = allocator,
        }) catch |err| {
            diagnostic.report(std.io.getStdErr().writer(), err) catch {};
            return err;
        };

        const template_name: ?[]const u8 = if (args.positionals.len == 1)
            args.positionals[0]
        else
            null;

        const config_dir_path: []const u8 = args.args.config orelse
            return error.MissingConfig;

        const current_dir_path = try std.fs.cwd().realpathAlloc(allocator, ".");

        var template_params = std.StringArrayHashMap([]const u8).init(allocator);
        for (args.args.param) |param_unparsed| {
            if (std.mem.indexOf(u8, param_unparsed, "=")) |split_index| {
                const key = param_unparsed[0..split_index];
                const value = param_unparsed[split_index + 1 ..];
                try template_params.put(key, value);
            } else {
                std.log.err("Parameter '{s}' has incorrect format, must be 'key=value'.", .{param_unparsed});
                return error.IncorrectTemplateParam;
            }
        }

        return .{
            .cli_args = args,
            .allocator = allocator,
            .template_name = template_name,
            .config_dir_path = config_dir_path,
            .current_dir_path = current_dir_path,
            .template_params = template_params,
        };
    }

    pub fn deinit(self: Context) void {
        self.cli_args.deinit();
    }

    pub const cli_params_help =
        \\    -h, --help             Display this help and exit.
        \\    -c, --config <str>     Config directory path.
        \\    -p, --param <str>...   Parameter to be replaced (ex. key=value)
        \\    <str>                  Template name
        \\
    ;

    pub const cli_help =
        \\init - commandline tool for creaing projects or other artifacts based on template.
        \\
        \\Usage: 
        \\    init <TEMPLATE> [-c|--config "path/to/config"] [-p|--param "key=value"]...
        \\
        \\Parameters:
        \\
    ++ cli_params_help ++
        \\
        \\Exmaple:
        \\    init zig-raylib --param "name=my-game"
        \\
    ;

    const cli_params = clap.parseParamsComptime(cli_params_help);

    const CliArgs = clap.Result(clap.Help, &cli_params, clap.parsers.default);
};
