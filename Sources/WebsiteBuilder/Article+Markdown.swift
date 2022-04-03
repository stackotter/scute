import Foundation

extension Article {
    static func fromMarkdownFile(at file: URL) throws -> Article {
        let markdown = try String(contentsOf: inputFile)
        let markdownHTML = try Markdown.html(from: markdown)

        let initialHTML = """
<div class='markdown-body'>
\(markdownHTML)
</div>
"""

        return Article(styleSheets: [], scripts: [], content: initialHTML)
    }
}
