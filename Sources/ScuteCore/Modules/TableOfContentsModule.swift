import Foundation
import SwiftSoup

public enum TableOfContentsModuleError: LocalizedError {
    case invalidHeadingTag(String)
}

/// A module that creates a simple table of contents from headings on a page.
///
/// The ``HeadingIDPlugin`` must be run before the ``ModuleRendererPlugin`` for the entries to link to the headings.
public struct TableOfContentsModule: Module {
    public static var name = "TableOfContents"

    public struct Parameters: Codable {
        public var depth: Int?
        public var stripEmojis: Bool?
    }

    public init() {}

    public func render(moduleElement: Element, with parameters: Parameters, page: Page) throws {
        let stripEmojis = parameters.stripEmojis ?? false
        let depth = parameters.depth ?? 6

        // First we get all headings so that the minimum depth can be calculated
        let cssQuery = (1...6).map { i in
            "h\(i)"
        }.joined(separator: ", ")

        // Search for all headings after the table of contents in the document
        var headings: [Element] = []
        var element: Element? = moduleElement
        while let currentElement = element {
            headings.append(contentsOf: Array(try currentElement.select(cssQuery)))

            // Move to the next element
            if let nextSibling = try currentElement.nextElementSibling() {
                element = nextSibling
            } else {
                // If there is no next sibling we have reached the end of the parent, so move to the parent's next sibling
                element = try currentElement.parent()?.nextElementSibling()
            }
        }

        // Process all headings to extract their text and level
        var tableOfContents: [(heading: String, id: String?, level: Int)] = []
        for heading in headings {
            // Get the heading's level
            let tag = heading.tag().getName()
            guard let level = Int(tag.dropFirst()) else {
                throw TableOfContentsModuleError.invalidHeadingTag(tag)
            }

            var text = try heading.text()

            // Remove emojis if configured to
            if stripEmojis {
                text = text.unicodeScalars.filter { scalar in
                    // TODO: Figure out how to fix this filter so that the hardcoded hammer emoji check isn't required
                    // (who knows what other emojis are also not being detected).
                    !(scalar.properties.isEmojiPresentation && scalar.properties.isEmoji)
                        && scalar != "🛠".unicodeScalars.first
                }.reduce("") { $0 + String($1) }
            }

            tableOfContents.append(
                (
                    heading: text,
                    id: try? heading.attr("id"),
                    level: level
                )
            )
        }

        let minimumLevel = tableOfContents.map(\.level).min() ?? 1

        tableOfContents = tableOfContents.filter { (text, id, level) in
            level < (minimumLevel + depth)
        }

        // Convert the headings to a list of links with indentation
        var html = ""
        for (index, (heading, id, level)) in tableOfContents.enumerated() {
            if index == 0 {
                let startingIndent = level - minimumLevel + 1
                html += Array(repeating: "<ul>", count: startingIndent).joined(separator: "<li>")
            }

            // Open the list item
            html += "<li>"

            // Only create a link if the heading has an id
            if let id = id {
                html += "<a href=\"#\(id)\">\(heading)</a>"
            } else {
                html += "\(heading)"
            }

            // Close the list item if the next item's level isn't higher
            let nextIndex = index + 1
            let nextLevel =
                nextIndex < tableOfContents.count ? tableOfContents[nextIndex].level : minimumLevel
            switch nextLevel {
                case level:
                    html += "</li>"
                case ..<level:
                    html +=
                        "</li>"
                        + Array(repeating: "</ul></li>", count: level - nextLevel).joined(
                            separator: "")
                case (level + 1)...:
                    html += Array(repeating: "<ul>", count: nextLevel - level).joined(
                        separator: "<li>")
                default:
                    assertionFailure("Switch over next level was not exhaustive")
            }
        }

        // Update the element
        try moduleElement.html(html)
        try moduleElement.tagName("p")
        try moduleElement.attr("class", "-table-of-contents")
    }
}
