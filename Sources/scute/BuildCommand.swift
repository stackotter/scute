import ArgumentParser
import Foundation
import ScuteCore

struct BuildCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Build a site for deployment."
    )

    @Option(
        name: [.customShort("i"), .customLong("in")],
        help: "The directory containing the site's sources.",
        transform: URL.init(fileURLWithPath:))
    var inputDirectory: URL

    @Option(
        name: [.customShort("o"), .customLong("out")],
        help: "The directory to output the built site to.",
        transform: URL.init(fileURLWithPath:))
    var outputDirectory: URL

    @Option(
        name: [.customShort("t"), .customLong("page-template")],
        help: "The template to use for rendering pages",
        transform: URL.init(fileURLWithPath:))
    var templateFile: URL

    func run() throws {
        let configuration = Site.Configuration(
            name: "stackotter",
            inputDirectory: inputDirectory,
            outputDirectory: outputDirectory,
            templateFile: templateFile
        )

        var site = Site(configuration)
        do {
            print("Building site")
            try site.addDefaultPlugins()
            try site.build()
        } catch {
            print("Failed to preview site: \(error)")
        }
    }
}
