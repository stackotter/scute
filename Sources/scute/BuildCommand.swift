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
        do {
            print("Building site")
            let site = try configuration.toSite(with: directory)
            try site.build()
        } catch {
            print("Failed to preview site: \(error)")
        }
    }
}
