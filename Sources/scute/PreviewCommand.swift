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
        do {
            let site = try configuration.toSite(with: directory)
            try await site.preview()
        } catch {
            // TODO: Output errors to stderr instead of stdout
            print("Failed to preview site: \(error)")
        }
    }
}
