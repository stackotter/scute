import Foundation
import Parsley
import Parsing

let theme = "monokai"
let inputFile = URL(fileURLWithPath: "test.md")
let outputFile = URL(fileURLWithPath: "output.html")

var pipeline = Pipeline()
pipeline.append(SyntaxHighlightingPlugin(context: .init(theme: theme)))
pipeline.append(HeadingIDPlugin())

do {
    var article = try Article.fromMarkdownFile(at: inputFile)

    try pipeline.process(&article)

    try article.html.write(to: outputFile, atomically: false, encoding: .utf8)
} catch {
    print("Error: \(error)")
}
