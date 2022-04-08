import Foundation
import SwiftSoup
import SwiftCSSParser
import Parsing

public struct CSSMinifierPlugin: Plugin {
    public static var name = "css_minifier"

    public init() {}

    public func process(_ pages: inout [Page], _ context: Void, site: Site.Configuration) throws {
        let stylesheets = Array(Set(pages.flatMap(\.stylesheets)))

        for stylesheet in stylesheets {
            let affectedPages = pages.enumerated().filter { (index: Int, page: Page) -> Bool in
                return page.stylesheets.contains { $0 == stylesheet }
            }

            guard !affectedPages.isEmpty else {
                continue
            }

            let sheetContent: String
            switch stylesheet {
                case .selfHosted(let path):
                    let file = site.outputDirectory.appendingPathComponent(path)
                    sheetContent = try String(contentsOf: file)
                case .inline(let content):
                    sheetContent = content
                case .external:
                    continue
            }

            let statements: [SwiftCSSParser.Statement]
            do {
                statements = try SwiftCSSParser.Stylesheet.parseStatements(from: sheetContent)
            } catch {
                throw error
            }

            // Filter out unused tokens
            let filteredStatements = try Self.removedUnusedRuleSets(from: statements, pages: pages)
            let minifiedSheet = Stylesheet(filteredStatements)
            let minifiedContents = minifiedSheet.minified()

            switch stylesheet {
                case .selfHosted(let path):
                    let file = site.outputDirectory.appendingPathComponent(path)
                    try minifiedContents.write(to: file, atomically: false, encoding: .utf8)
                case .inline:
                    for (index, _) in affectedPages {
                        guard let stylesheetIndex = pages[index].stylesheets.firstIndex(of: stylesheet) else {
                            print("Failed to minify stylesheet: \(stylesheet)")
                            continue
                        }

                        pages[index].stylesheets[stylesheetIndex] = .inline(content: minifiedContents)
                    }
                case .external:
                    // This shouldn't happen, but we just ignore it if it does
                    continue
            }
        }
    }

    static func removedUnusedRuleSets(from statements: [Statement], pages: [Page]) throws -> [Statement] {
        var filteredStatements: [Statement] = []
        for statement in statements {
            switch statement {
                case .ruleSet(let ruleSet):
                    if try Self.isRuleSetUsed(ruleSet, in: pages) {
                        filteredStatements.append(statement)
                    }
                case .atBlock(let block):
                    let blockFilteredStatements = try Self.removedUnusedRuleSets(from: block.statements, pages: pages)
                    if !block.statements.isEmpty {
                        filteredStatements.append(.atBlock(AtBlock(
                            identifier: block.identifier,
                            statements: blockFilteredStatements
                        )))
                    }
                case .importRule, .charsetRule, .namespaceRule:
                    filteredStatements.append(statement)
            }
        }
        return filteredStatements
    }

    static func isRuleSetUsed(_ ruleSet: RuleSet, in pages: [Page]) throws -> Bool {
        // Remove pseudo-selectors from the query
        let query: String
        do {
            query = try Self.queryCleaningParser.parse(ruleSet.selector)
        } catch {
            throw error
        }

        // Figure out whether any page matche the selector
        var isUsed = false
        for page in pages {
            do {
                if !(try page.content.select(query).isEmpty()) {
                    isUsed = true
                    break
                }
            } catch {
                throw error
            }
        }

        return isUsed
    }

    static let selectorCharacters: CharacterSet = {
        var characters = CharacterSet.alphanumerics
        characters.insert(charactersIn: "-_")
        return characters
    }()

    static let commaAndWhitespaces: CharacterSet = {
        var characters = CharacterSet.whitespacesAndNewlines
        characters.insert(charactersIn: ",")
        return characters
    }()

    // Given a string such as ' , h1' this should return ',', and given a string such as '  h1' this should return ' '
    static let selectorSeparatorParser = Parse {
        Whitespace()
        Optionally {
            Parse(",") { "," }
        }.map { $0 ?? " " }
        Whitespace()
    }.map { _, separator, _ in
        separator
    }

    // Parses a selector's prefix if any
    static let selectorPrefixParser = Optionally {
        OneOf {
            Parse("#") { "#" }
            Parse(".") { "." }
        }
    }.map { $0 ?? "" }

    // Given a string such as ".content::before, h1", this should extract ".content," and advance the reader to the first character of h1
    static let selectorCleaningParser = Parse {
        // Either "#", "." or ""
        selectorPrefixParser

        // Read the selector and stop before any pseudo-selectors
        OneOf {
            Prefix(1...) { (character: Character) -> Bool in
                let singleCharacterSet = CharacterSet(charactersIn: String(character))
                return selectorCharacters.isSuperset(of: singleCharacterSet)
            }.map(String.init)

            // Skip selectors such as `[hidden]`
            Parse("") { "[" }

            // Skip selectors starting with a colon
            Parse("") { ":" }
        }

        // Skip all characters up to the next comma, whitespace or the end of the input
        OneOf {
            Parse {
                Prefix { (character: Character) -> Bool in
                    let singleCharacterSet = CharacterSet(charactersIn: String(character))
                    return !commaAndWhitespaces.isSuperset(of: singleCharacterSet)
                }.map(String.init)

                // Get the separator between this selector and the next (either "," or " "). Returns " " if this is the last selector in the query.
                selectorSeparatorParser
            }.map { _, separator in
                separator
            }
            // If this is the last selector and isn't followed by any trailing whitespace, return "" as the separator
            Parse {
                Rest().map { _ in
                    ""
                }
                End()
            }
        }
    }.map { prefixCharacter, selector, separator in
        // The separator is the character separating this selector from the next
        prefixCharacter + selector + separator
    }

    // Given a string such as '.content::before, h1 div', this should return '.content,h1 div' (removing all but the element selectors)
    static let queryCleaningParser = Many {
        selectorCleaningParser
    }.map { selectors in
        selectors.joined(separator: "").trimmingCharacters(in: .whitespaces)
    }
}
