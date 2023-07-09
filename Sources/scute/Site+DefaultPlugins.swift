import ScuteCore

extension Site {
    mutating func addDefaultPlugins(syntaxTheme: String) throws {
        try addPlugin(GitHubMarkdownThemePlugin(configuration: .init(theme: .light)))
        try addPlugin(HeadingIDPlugin())
        try addPlugin(
            ModuleRendererPlugin(
                configuration: {
                    var moduleRendererConfiguration = ModuleRendererPlugin.Configuration()
                    moduleRendererConfiguration.addModule(TableOfContentsModule())
                    moduleRendererConfiguration.addModule(
                        ArticleIndexModule(
                            configuration: .init(inputDirectory: configuration.inputDirectory)
                        ))
                    return moduleRendererConfiguration
                }()
            )
        )
        try addPlugin(CSSMinifierPlugin())
        try addPlugin(SyntaxHighlighterPlugin(configuration: .init(theme: syntaxTheme)))
    }
}
