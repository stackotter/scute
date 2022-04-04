import Foundation

@main
struct Scute {
    static let inputDirectory = URL(fileURLWithPath: "src")
    static let outputDirectory = URL(fileURLWithPath: "out")
    static let templateDirectory = URL(fileURLWithPath: "template")

    static func build() throws {
        let start = CFAbsoluteTimeGetCurrent()

        // Clear the output directory
        try? FileManager.default.removeItem(at: outputDirectory)

        // Copy the input files to the output directory
        try FileManager.default.copyItem(at: inputDirectory, to: outputDirectory)

        // TODO: make a better way of doing this
        try FileManager.default.createDirectory(at: outputDirectory.appendingPathComponent("css"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outputDirectory.appendingPathComponent("js"), withIntermediateDirectories: true)

        // Create page processing pipeline
        var pipeline = Pipeline(toProcess: outputDirectory)
        try pipeline.append(SyntaxHighlightingPlugin(configuration: .init(theme: "atom-one-dark")))
        try pipeline.append(GitHubMarkdownThemePlugin(configuration: .init(theme: .light)))
        try pipeline.append(HeadingIDPlugin())
        try pipeline.append(PageTemplatePlugin(configuration: .init(templateDirectory: templateDirectory)))

        // Processes the files in the output directory
        try pipeline.processDirectory(outputDirectory)

        let elapsed = String(format: "%.02fms", (CFAbsoluteTimeGetCurrent() - start) * 1000)
        print("Built site in \(elapsed)")
    }

    static func main() async throws {
        // Quit the program on interrupt (the server sometimes doesn't like stopping)
        trap(.interrupt, action: { _ in
            Foundation.exit(1)
        })

        // Build the site
        print("Building site")
        try build()

        // Rebuild site when any input files change
        print("Watching file system for changes")
        try FileSystemWatcher.startWatchingForDebouncedModifications(paths: [inputDirectory.path, templateDirectory.path], with: {
            do {
                print("Detected changes, rebuilding site")
                try build()
                print("Successfully rebuilt site")
            } catch {
                print("Failed to rebuild site: \(error)")
            }
        }, errorHandler: { error in
            print("Error procssing file system event: \(error)")
        })

        // Host the site
        try await Server.host(outputDirectory, onPort: 80)
    }
}
