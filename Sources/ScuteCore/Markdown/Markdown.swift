import Parsley
import CMarkExtension

public enum Markdown {
    public static func html(from markdown: String) throws -> String {
        return try Parsley.html(
            markdown,
            options: [.unsafe, .smartQuotes],
            syntaxExtensions: SyntaxExtension.defaultExtensions + [.custom({
                create_module_syntax_extension()
            })]
        )
    }

    public static func document(from markdown: String) throws -> Document {
        return try Parsley.parse(
            markdown,
            options: [.unsafe, .smartQuotes],
            syntaxExtensions: SyntaxExtension.defaultExtensions + [.custom({
                create_module_syntax_extension()
            })]
        )
    }
}
