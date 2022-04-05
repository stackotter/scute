import Foundation
import ScuteCore

@main
struct Scute {
    static let inputDirectory = URL(fileURLWithPath: "src")
    static let outputDirectory = URL(fileURLWithPath: "out")
    static let templateDirectory = URL(fileURLWithPath: "template")

    static func main() async throws {
        // Configure site
        var site = Site(
            inputDirectory: inputDirectory,
            outputDirectory: outputDirectory
        )

        // Register plugins
        try site.addPlugin(SyntaxHighlighterPlugin(configuration: .init(theme: "atom-one-dark")))
        try site.addPlugin(GitHubMarkdownThemePlugin(configuration: .init(theme: .light)))
        try site.addPlugin(HeadingIDPlugin())
        try site.addPlugin(ModuleRendererPlugin(configuration: {
            var moduleRendererConfiguration = ModuleRendererPlugin.Configuration()
            moduleRendererConfiguration.addModule(TableOfContentsModule())
            return moduleRendererConfiguration
        }()))
        try site.addPlugin(PageTemplatePlugin(configuration: .init(templateDirectory: templateDirectory)))

        // Run site
        await site.main()
    }
}
