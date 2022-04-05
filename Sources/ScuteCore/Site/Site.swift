import Foundation

public struct Site {
    public let inputDirectory: URL
    public let outputDirectory: URL

    private var pipeline: Pipeline

    public init(inputDirectory: URL, outputDirectory: URL) {
        self.inputDirectory = inputDirectory
        self.outputDirectory = outputDirectory

        pipeline = Pipeline(
            inputDirectory: inputDirectory,
            outputDirectory: outputDirectory
        )
    }

    public func main() async -> Never {
        do {
            // Quit the program on interrupt (the server sometimes doesn't like stopping)
            trap(.interrupt, action: { _ in
                Foundation.exit(0)
            })

            // Build the site
            print("Building site")
            try build()

            // Rebuild site when any input files change
            print("Watching file system for changes")
            try FileSystemWatcher.startWatchingForDebouncedModifications(paths: [inputDirectory.path], with: {
                do {
                    print("Detected changes, rebuilding site")
                    try build()
                    print("Successfully rebuilt site")
                } catch {
                    print("Failed to rebuild site: \(error)")
                    Foundation.exit(1)
                }
            }, errorHandler: { error in
                print("Error processing file system event: \(error)")
                Foundation.exit(1)
            })

            // Host the site
            try await Server.host(outputDirectory, onPort: 80)
        } catch {
            print("Failed to run site: \(error)")
            Foundation.exit(1)
        }
        Foundation.exit(0)
    }

    public func build() throws {
        try pipeline.buildSite()
    }

    public mutating func addPlugin<T: Plugin>(_ plugin: T) throws {
        try pipeline.append(plugin)
    }
}
