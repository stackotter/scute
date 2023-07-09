import ArgumentParser
import ScuteCore

@main
struct ScuteCLI: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A Site Creation (u) Tool (e).",
        subcommands: [BuildCommand.self, PreviewCommand.self],
        defaultSubcommand: PreviewCommand.self
    )
}
