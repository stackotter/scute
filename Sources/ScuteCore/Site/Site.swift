import Foundation

public struct Site {
    public let configuration: Configuration

    private var pipeline: Pipeline

    public init(_ configuration: Configuration) {
        self.configuration = configuration
        pipeline = Pipeline(configuration)
    }

    public func build() throws {
        try pipeline.buildSite()
    }

    public func preview(on port: UInt16) async throws {
        // Quit the program on interrupt (the server sometimes doesn't like stopping)
        #if canImport(Darwin)
        trap(
            .interrupt,
            action: { _ in
                Foundation.exit(0)
            })
        #endif

        // Build the site
        print("Building site")
        try build()

        // Rebuild site when any input files change
        print("Watching file system for changes")
        let pathsToWatch = [
            configuration.inputDirectory.path,
            configuration.templateFile.path,
        ]

        #if canImport(CoreServices)
        try FileSystemWatcher.startWatchingForDebouncedModifications(
            paths: pathsToWatch,
            with: {
                do {
                    print("Detected changes, rebuilding site")
                    try build()
                    print("Successfully rebuilt site")
                } catch {
                    print("Failed to rebuild site: \(error)")
                    Foundation.exit(1)
                }
            },
            errorHandler: { error in
                print("Error processing file system event: \(error)")
                Foundation.exit(1)
            })
        #else
        print("Warning: File watching isn't implemented yet on non-Apple platforms. Rerun the preview command to rebuild.")
        #endif

        // Host the site
        try await Server.host(configuration.outputDirectory, onPort: port)
    }

    public mutating func addPlugin<T: Plugin>(_ plugin: T) throws {
        try pipeline.append(plugin)
    }
}
