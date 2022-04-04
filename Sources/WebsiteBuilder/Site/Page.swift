import Foundation

struct Page {
    var styleSheets: [StyleSheet]
    var scripts: [Script]
    var content: String

    static func fromMarkdownFile(at file: URL) throws -> Page {
        let markdown = try String(contentsOf: file)
        let markdownHTML = try Markdown.html(from: markdown)

        let html = """
<div class='markdown-body'>
\(markdownHTML)
</div>
"""

        return Page(styleSheets: [], scripts: [], content: html)
    }

    func toHTML() -> String {
        return """
<head>
\(styleSheets.map(\.html).joined(separator: "\n"))
\(scripts.map(\.html).joined(separator: "\n"))
</head>

\(content)
"""
    }
}
