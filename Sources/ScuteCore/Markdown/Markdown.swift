import Parsley
import CMarkExtension

public enum Markdown {
    public static func html(from markdown: String) throws -> String {
        return try Parsley.html(
            markdown,
            options: [.unsafe, .hardBreaks],
            syntaxExtensions: SyntaxExtension.defaultExtensions + [.custom({
                create_custom_strikethrough_extension()
            })]
        )
    }
}
