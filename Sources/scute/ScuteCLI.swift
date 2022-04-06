import Foundation
import ScuteCore

@main
struct ScuteCLI {
    static let inputDirectory = URL(fileURLWithPath: "src")
    static let outputDirectory = URL(fileURLWithPath: "out")
    static let templateFile = URL(fileURLWithPath: "src/_template.html")

    static func main() async throws {
        let configuration = Site.Configuration(
            name: "stackotter",
            inputDirectory: inputDirectory,
            outputDirectory: outputDirectory,
            templateFile: templateFile
        )

        // Configure site
        var site = Site(configuration)

        // Register plugins
        try site.addPlugin(SyntaxHighlighterPlugin(configuration: .init(theme: "atom-one-dark")))
        try site.addPlugin(GitHubMarkdownThemePlugin(configuration: .init(theme: .light)))
        try site.addPlugin(HeadingIDPlugin())
        try site.addPlugin(ModuleRendererPlugin(configuration: {
            var moduleRendererConfiguration = ModuleRendererPlugin.Configuration()
            moduleRendererConfiguration.addModule(TableOfContentsModule())
            moduleRendererConfiguration.addModule(ArticleIndexModule(
                configuration: .init(inputDirectory: inputDirectory)
            ))
            return moduleRendererConfiguration
        }()))

        // Run site
        await site.main()
    }
}
