import Parsing

public enum CSS {
    public static func parseDocument(_ input: String) -> Result<Document, CSSError> {
        return removeComments(from: input)
            .flatMap { inputWithoutComments in
                parseCommentlessDocument(inputWithoutComments)
            }
    }

    private static func parseCommentlessDocument(_ input: String) -> Result<Document, CSSError> {
        do {
            let blocks: [Block] = try documentParser.parse(input)
            return .success(Document(blocks: blocks))
        } catch {
            return .failure(.failedToParseDocument(error))
        }
    }

    private static func removeComments(from input: String) -> Result<String, CSSError> {
        do {
            let inputWithoutComments = try commentRemovingParser.parse(input)
            return .success(inputWithoutComments)
        } catch {
            return .failure(.failedToRemoveComments(error))
        }
    }

    // MARK: Document parsing

    private static let ruleParser = Parse {
        Prefix { $0 != ":" }
        ":"
        Prefix { $0 != ";" && $0 != "}" }
    }.map { key, value in
        Rule(
            property: String(key.trimmingCharacters(in: .whitespacesAndNewlines)),
            value: String(value.trimmingCharacters(in: .whitespacesAndNewlines))
        )
    }

    private static let blockParser = Parse {
        Prefix { $0 != "{" }.map { selector in
            String(selector).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        "{"
        Many {
            ruleParser
        } separator: {
            ";"
        }
        Optionally {
            ";"
        }
        "}"
    }.map { selector, rules, _ in
        Block(
            selector: selector,
            rules: rules
        )
    }

    private static let documentParser = Parse {
        Many {
            blockParser
        }
        End()
    }

    // MARK: Comment parsing/removing

    private static let commentParser = Parse(String.init) {
        "/*"
        PrefixUpTo("*/").map(String.init)
        "*/"
    }

    private static let commentRemovingParser = Parse {
        OneOf {
            PrefixUpTo("/*")
            Rest()
        }.map(String.init)
        Many {
            commentParser
            OneOf {
                PrefixUpTo("/*")
                Rest()
            }
        }.map { array in
            array.map { _, code in String(code) }
        }
        End()
    }.map { code, moreCode in
        code + moreCode.joined(separator: "")
    }
}
