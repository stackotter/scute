import Foundation
import Parsley
import Parsing

func main() throws {
    // Configuration
    let inputDirectory = URL(fileURLWithPath: "src")
    let outputDirectory = URL(fileURLWithPath: "out")

    // Clear the output directory
    try? FileManager.default.removeItem(at: outputDirectory)

    // Copy the input files to the output directory
    try FileManager.default.copyItem(at: inputDirectory, to: outputDirectory)

    // TODO: make a better way of doing this
    try FileManager.default.createDirectory(at: outputDirectory.appendingPathComponent("css"), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: outputDirectory.appendingPathComponent("js"), withIntermediateDirectories: true)

    // Create page processing pipeline
    var pipeline = Pipeline(toProcess: outputDirectory)
    try pipeline.append(SyntaxHighlightingPlugin(configuration: .init(theme: "monokai")))
    try pipeline.append(GitHubMarkdownThemePlugin(configuration: .init(theme: .light)))
    try pipeline.append(HeadingIDPlugin())

    // Processes the files in the output directory
    try pipeline.processDirectory(outputDirectory)
}

do {
    try main()
} catch {
    print("Error: \(error)")
}
