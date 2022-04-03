import Foundation

struct GitHubMarkdownThemePlugin: Plugin {
    var configuration: Configuration

    enum Theme: String {
        case light
        case dark
    }

    struct Configuration {
        var theme: Theme
    }

    struct Context {
        var cssFilePath: String
    }

    func setup(in directory: URL) throws -> Context {
        let url = URL(string: "https://raw.githubusercontent.com/sindresorhus/github-markdown-css/main/github-markdown-\(configuration.theme.rawValue).css")!
        let cssFilePath = "/css/github-markdown-\(configuration.theme.rawValue)"
        try String(contentsOf: url).write(to: directory.appendingPathComponent(cssFilePath), atomically: true, encoding: .utf8)

        return Context(
            cssFilePath: cssFilePath
        )
    }

    func process(_ page: inout Page, _ context: Context) throws {
        page.styleSheets += [
            .externalSheet(url: context.cssFilePath)
        ]
    }
}
