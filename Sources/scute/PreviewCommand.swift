import ArgumentParser
import Foundation
import ScuteCore

struct PreviewCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "preview",
        abstract: "Preview a site locally."
    )

    @Option(
        name: [.customShort("i"), .customLong("in")],
        help: "The directory containing the site's sources.",
        transform: URL.init(fileURLWithPath:))
    var inputDirectory: URL

    @Option(
        name: [.customShort("o"), .customLong("out")],
        help: "The directory to output the built site to while previewing.",
        transform: URL.init(fileURLWithPath:))
    var outputDirectory: URL

    @Option(
        name: [.customShort("t"), .customLong("page-template")],
        help: "The template to use for rendering pages",
        transform: URL.init(fileURLWithPath:))
    var templateFile: URL

    func run() async throws {
        let configuration = Site.Configuration(
            name: "stackotter",
            inputDirectory: inputDirectory,
            outputDirectory: outputDirectory,
            templateFile: templateFile
        )

        var site = Site(configuration)
        do {
            try site.addDefaultPlugins()
            try await site.preview()
        } catch {
            print("Failed to preview site: \(error)")
        }
    }
}
