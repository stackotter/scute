import Foundation

public struct GitHubMarkdownThemePlugin: Plugin {
    public static var name = "GitHubMarkdownTheme"

    public var configuration: Configuration

    public enum Theme: String {
        case light
        case dark
    }

    public struct Configuration {
        public var theme: Theme

        public init(theme: GitHubMarkdownThemePlugin.Theme) {
            self.theme = theme
        }
    }

    public struct Context {
        public var cssFilePath: String
    }

    public init(configuration: GitHubMarkdownThemePlugin.Configuration) {
        self.configuration = configuration
    }

    public func setup(in directory: URL) throws -> Context {
        let url = URL(string: "https://raw.githubusercontent.com/sindresorhus/github-markdown-css/main/github-markdown-\(configuration.theme.rawValue).css")!
        let cssFilePath = "/css/github-markdown-\(configuration.theme.rawValue).css"
        try String(contentsOf: url).write(to: directory.appendingPathComponent(cssFilePath), atomically: true, encoding: .utf8)

        return Context(
            cssFilePath: cssFilePath
        )
    }

    public func process(_ page: inout Page, _ context: Context) throws {
        page.styleSheets += [
            .externalSheet(url: context.cssFilePath)
        ]
    }
}
