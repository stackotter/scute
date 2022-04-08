import Foundation
import SwiftCSSParser

public enum SyntaxHighlighterPluginError: LocalizedError {
    case failedToGetThemeBackgroundColor
}

public struct SyntaxHighlighterPlugin: Plugin {
    public static var name = "syntax_highlighter"
    
    public let configuration: Configuration

    public struct Configuration {
        public init(theme: String) {
            self.theme = theme
        }

        public var theme: String
    }

    public struct Context {
        public var highlightJSFilePath: String
        public var themeCSSFilePath: String
        public var additionalStyles: String
    }

    public init(configuration: SyntaxHighlighterPlugin.Configuration) {
        self.configuration = configuration
    }

    public func setup(in directory: URL) throws -> Context {
        // Download highlight.min.js
        let highlightJSURL = URL(string: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.5.0/highlight.min.js")!
        let highlightJSFilePath = "/js/highlight.min.js"
        let highlightJSFile = directory.appendingPathComponent(highlightJSFilePath)
        let highlightJSScriptContents = try String(contentsOf: highlightJSURL) + "\nhljs.highlightAll();"
        try highlightJSScriptContents.write(to: highlightJSFile, atomically: false, encoding: .utf8)

        // Download theme
        let themeURL = URL(string: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.5.0/styles/\(configuration.theme).min.css")!
        let cssFilePath = "/css/syntax-theme_\(configuration.theme).min.css"
        let cssFile = directory.appendingPathComponent(cssFilePath)
        let css = try String(contentsOf: themeURL)
        try css.write(to: cssFile, atomically: false, encoding: .utf8)

        // Parse the theme's CSS
        let cssTokens = try SwiftCSSParser.Stylesheet.parse(from: css).tokens

        // Iterate through the css tokens to find the background color for `.hljs`
        let selector = ".hljs"
        var backgroundColor: String? = nil
        var iterator = cssTokens.makeIterator()
    outerLoop:
        while let token = iterator.next() {
            guard token.type == .selectorStart else {
                continue
            }

            if token.data == selector {
                while let token = iterator.next(), token.type != .selectorEnd {
                    if token.type == .property && (token.data == "background" || token.data == "background-color") {
                        guard let backgroundValue = iterator.next() else {
                            break outerLoop
                        }
                        backgroundColor = backgroundValue.data
                        break outerLoop
                    }
                }
            }
        }

        guard let backgroundColor = backgroundColor else {
            throw SyntaxHighlighterPluginError.failedToGetThemeBackgroundColor
        }

        let themeBackgroundColor = backgroundColor

        // Override some styles to make it work nicely with GitHubMarkdownTheme
        let additionalStyles = """
pre code.hljs {
    padding: 0 !important;
}

.markdown-body .highlight pre,
.markdown-body pre {
    background-color: \(themeBackgroundColor) !important;
}
"""

        // Return the context used to process individual pages
        return Context(
            highlightJSFilePath: highlightJSFilePath,
            themeCSSFilePath: cssFilePath,
            additionalStyles: additionalStyles
        )
    }

    public func process(_ page: inout Page, _ context: Context) throws {
        // Only add highlight.js if the page contains a code block
        if try page.content.getElementsByTag("pre").isEmpty() {
            return
        }

        page.styleSheets += [
            .selfHosted(path: context.themeCSSFilePath),
            .inline(content: context.additionalStyles)
        ]
        
        page.scripts += [
            .externalScript(url: context.highlightJSFilePath, shouldDefer: true)
        ]
    }
}
