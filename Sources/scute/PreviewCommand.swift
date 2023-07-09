import ArgumentParser
import Foundation
import ScuteCore

struct PreviewCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "preview",
        abstract: "Preview a site locally."
    )

    @Option(
        name: .shortAndLong,
        help: "The root directory of the scute project to preview.",
        transform: URL.init(fileURLWithPath:))
    var directory: URL?

    func run() async throws {
        let directory = directory.orCWD
        let configuration = try Configuration.load(fromDirectory: directory)
        try configuration.validate(with: directory)

        var site = configuration.toSite(with: directory)
        do {
            try site.addDefaultPlugins()
            try await site.preview()
        } catch {
            print("Failed to preview site: \(error)")
        }
    }
}
