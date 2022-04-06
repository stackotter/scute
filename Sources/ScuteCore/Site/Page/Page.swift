import Foundation
import Parsing
import SwiftSoup

public enum PageError: LocalizedError {
    case unknownTemplateVariable(String)
    case pageMustContainAHeadTag
}

public struct Page {
    public static let defaultTemplate = """
<html>
<head>
    <title>{title}</title>
</head>
<body>
    <div>{content}</div>
</body>
</html>
"""

    public var styleSheets: [StyleSheet]
    public var scripts: [Script]
    public var content: Element

    private static let templateParser = Parse {
        Many {
            Prefix { $0 != "{" }.map(String.init)
            "{"
            Prefix { $0 != "}" }.map(String.init)
            "}"
        }.map { parts in
            parts.map { (content, variable) in
                (content: content, variable: variable)
            }
        }
        Rest().map(String.init)
    }

    public static func fromMarkdownFile(at file: URL, forSite site: Site.Configuration) throws -> Page {
        let markdown = try String(contentsOf: file)
        let document = try Markdown.document(from: markdown)

        // Load the contents of the template to use (a default template is used if no template was specified
        var templateContents: String
        if let template = site.templateFile {
            templateContents = try String(contentsOf: template)
        } else {
            templateContents = Self.defaultTemplate
        }

        // The title for the page tab
        let title = (document.title.map({ "\($0) - " }) ?? "") + site.name

        // The value to substitute for each variable
        let templateVariables: [String: String] = [
            "title": title,
            "content": """
\(document.title.map({ "<h1>\($0)</h1>" }) ?? "")
\(document.body)
"""
        ]

        // Parse the template and perform variable substitution
        let (parts, rest) = try templateParser.parse(templateContents)
        var html = ""
        for (content, variable) in parts {
            guard let value = templateVariables[variable] else {
                throw PageError.unknownTemplateVariable(variable)
            }

            html += content + value
        }
        html += rest

        let parsedHTML = try SwiftSoup.parse(html)

        return Page(styleSheets: [], scripts: [], content: parsedHTML)
    }

    func toHTML() throws -> String {
        guard let head = try content.getElementsByTag("head").first() else {
            throw PageError.pageMustContainAHeadTag
        }

        try head.append(styleSheets.map(\.html).joined(separator: ""))
        try head.append(scripts.map(\.html).joined(separator: ""))

        return try content.outerHtml()
    }
}
