import SwiftSoup
import Foundation

public struct HeadingIDPlugin: Plugin {
    public static var name = "heading_ids"

    public init() {}

    public func process(_ page: inout Page, _ context: Void) throws {
        // TODO: handle naming collisions

        let headings = try page.content.select("h1, h2, h3, h4, h5, h6")

        for heading in headings {
            let text = try heading.text(trimAndNormaliseWhitespace: true)

            // Remove disallowed characters and trailing/leading whitespace
            let filteredText = text.unicodeScalars
                .filter { (unicodeScalar: UnicodeScalar) -> Bool in
                    unicodeScalar.properties.isAlphabetic
                    || unicodeScalar.properties.isASCIIHexDigit // there's no category for digits, but this is sufficient
                    || unicodeScalar == " "
                    || unicodeScalar == "-"
                    || unicodeScalar == "_"
                    || unicodeScalar == "."
                    || unicodeScalar == ":"
                }
                .reduce("") { (partialResult: String, element: UnicodeScalar) -> String in
                    partialResult + String(element)
                }

            let trimmedText = filteredText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: .punctuationCharacters)

            // Replace spaces with hyphens and convert to lowercase
            let id = trimmedText.lowercased().replacingOccurrences(of: " ", with: "-")

            try heading.attr("id", id)
        }
    }
}
