import ArgumentParser
import Foundation
import ScuteCore

struct BuildCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Build a site for deployment."
    )

    @Option(
        name: .shortAndLong,
        help: "The root directory of the scute project to preview.",
        transform: URL.init(fileURLWithPath:))
    var directory: URL?

    func run() throws {
        let directory = directory.orCWD
        let configuration = try Configuration.load(fromDirectory: directory)
        try configuration.validate(with: directory)

        var site = configuration.toSite(with: directory)
        do {
            print("Building site")
            try site.addDefaultPlugins()
            try site.build()
        } catch {
            print("Failed to preview site: \(error)")
        }
    }
}
