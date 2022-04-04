import SwiftSoup
import Foundation

public struct HeadingIDPlugin: Plugin {
    public init() {}

    public func process(_ page: inout Page, _ context: Void) throws {
        // TODO: handle naming collisions

        let document = try SwiftSoup.parse(page.content)
        let headings = try document.select("h1, h2, h3, h4, h5, h6")

        for heading in headings {
            let text = try heading.text(trimAndNormaliseWhitespace: true)

            // Remove disallowed characters and trailing/leading whitespace
            let filteredText = text.unicodeScalars
                .filter {
                    $0.properties.isAlphabetic
                    || $0.properties.isASCIIHexDigit // there's no category for digits, but this is sufficient
                    || $0 == " "
                    || $0 == "-"
                    || $0 == "_"
                    || $0 == "."
                    || $0 == ":"
                }
                .reduce("") { $0 + String($1) }

            let trimmedText = filteredText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: .punctuationCharacters)

            // Replace spaces with hyphens and convert to lowercase
            let id = trimmedText.lowercased().replacingOccurrences(of: " ", with: "-")

            try heading.attr("id", id)
        }

        page.content = try document.outerHtml()
    }
}
