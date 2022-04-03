import Parsing

extension CSS {
    // MARK: Document parsing

    static let ruleParser = Parse {
        Prefix { $0 != ":" }
        ":"
        Prefix { $0 != ";" && $0 != "}" }
    }.map { key, value in
        Rule(
            property: String(key.trimmingCharacters(in: .whitespacesAndNewlines)),
            value: String(value.trimmingCharacters(in: .whitespacesAndNewlines))
        )
    }

    static let blockParser = Parse {
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

    static let documentParser = Parse {
        Many {
            blockParser
        }
        End()
    }

    // MARK: Comment parsing/removing

    static let commentParser = Parse(String.init) {
        "/*"
        PrefixUpTo("*/").map(String.init)
        "*/"
    }

    static let commentRemovingParser = Parse {
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
