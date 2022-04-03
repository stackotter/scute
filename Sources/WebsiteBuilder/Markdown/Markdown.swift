import Parsley

enum Markdown {
    static func html(from markdown: String) throws -> String {
        return try Parsley.html(markdown)
    }
}
