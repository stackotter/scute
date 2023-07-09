import ArgumentParser
import ScuteCore

@main
struct ScuteCLI: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A Site Creation (u) Tool (e).",
        version: "0.1.0",
        subcommands: [PreviewCommand.self, BuildCommand.self, CreateCommand.self],
        defaultSubcommand: PreviewCommand.self
    )
}
