import Foundation
import Parsing
import SwiftSoup

public enum PageError: LocalizedError {
    case unknownTemplateVariable(String)
    case pageMustContainAHeadTag
    case failedToGenerateDescription(URL)
}

public struct Page {
    public var stylesheets: [Stylesheet]
    public var scripts: [Script]
    public var content: Element

    private static let templateParser = Parse {
        Many {
            Prefix<Substring> { $0 != "{" }.map(String.init)
            "{"
            Prefix<Substring> { $0 != "}" }.map(String.init)
            "}"
        }.map { parts in
            parts.map { content, variable in
                (content: content, variable: variable)
            }
        }
        Rest<Substring>().map(String.init)
    }

    public static func fromMarkdownFile(
        at file: URL,
        forSite site: Site.Configuration
    ) throws -> Page {
        let markdown = try String(contentsOf: file)
        let document = try Markdown.document(from: markdown)

        // Load the contents of the template to use
        let templateContents = try String(contentsOf: site.templateFile)

        // The title for the page tab
        let title = (document.title.map({ "\($0) - " }) ?? "") + site.name

        // Generate a description
        let parsedBody = try SwiftSoup.parse(document.body)
        let description: String
        if let value = document.metadata["description"] {
            description = value
        } else if let firstParagraph = try? parsedBody.getElementsByTag("p").first() {
            description = try firstParagraph.text()
        } else {
            throw PageError.failedToGenerateDescription(file)
        }

        // The value to substitute for each variable
        let templateVariables: [String: String] = [
            "site_name": site.name,
            "title": title,
            "description": description,
            "content": """
            \(document.title.map({ "<h1>\($0)</h1>" }) ?? "")
            \(document.body)
            """,
        ]

        // Parse the template and perform variable substitution
        let (parts, rest) = try templateParser.parse(templateContents)
        var html = ""
        for (content, variable) in parts {
            guard !variable.contains("\n") else {
                continue
            }

            guard let value = templateVariables[variable] else {
                throw PageError.unknownTemplateVariable(variable)
            }

            html += content + value
        }
        html += rest

        let parsedHTML = try SwiftSoup.parse(html)

        return Page(
            stylesheets: [.selfHosted(path: "/css/page.css")], scripts: [], content: parsedHTML)
    }

    func toHTML() throws -> String {
        guard let head = try content.getElementsByTag("head").first() else {
            throw PageError.pageMustContainAHeadTag
        }

        try head.append(stylesheets.map(\.html).joined(separator: ""))
        try head.append(scripts.map(\.html).joined(separator: ""))

        return try content.outerHtml()
    }
}
