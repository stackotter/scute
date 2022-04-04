import Parsley

public enum Markdown {
    public static func html(from markdown: String) throws -> String {
        return try Parsley.html(markdown, options: [.unsafe, .smartQuotes, .hardBreaks])
    }
}
