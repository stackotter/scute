import ArgumentParser
import ScuteCore

@main
struct ScuteCLI: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A Site Creation (u) Tool (e).",
        subcommands: [PreviewCommand.self, BuildCommand.self, CreateCommand.self],
        defaultSubcommand: PreviewCommand.self
    )
}
