import Foundation

struct SyntaxHighlightingPlugin: Plugin {
    let context: Context

    struct Context {
        var theme: String
    }

    func process(_ article: inout Article) throws {
        let themeURL = URL(string: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.5.0/styles/\(context.theme).min.css")!

        let themeCSS = try String(contentsOf: themeURL)
        let document = try CSS.parseDocument(themeCSS).unwrap()

        guard
            let hljsBlock = document.blocks.filter({ $0.selector == ".hljs" }).first,
            let backgroundRule = hljsBlock.rules
                .filter({ $0.property == "background" || $0.property == "background-color" })
                .first
        else {
            print("Failed to get theme background color")
            Foundation.exit(1)
        }

        let themeBackgroundColor = backgroundRule.value

        let stylesheet = """
pre code.hljs {
    padding: 0 !important;
}

.markdown-body .highlight pre,
.markdown-body pre {
    background-color: \(themeBackgroundColor) !important;
}
"""

        article.styleSheets += [
            .hosted(url: "./github-markdown-light.css"),
            .hosted(url: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.5.0/styles/\(context.theme).min.css"),
            .inline(content: stylesheet)
        ]
        article.scripts += [
            .hosted(url: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.5.0/highlight.min.js"),
            .inline(contents: "hljs.highlightAll();")
        ]
    }
}
