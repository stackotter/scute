import Foundation

enum Command: String {
    case build
    case preview
}

public struct Site {
    public let configuration: Configuration

    private var pipeline: Pipeline

    public init(_ configuration: Configuration) {
        self.configuration = configuration
        pipeline = Pipeline(configuration)
    }

    public func main() async -> Never {
        func exitWithUsage() -> Never {
            print("Usage: scute [build|preview]")
            Foundation.exit(1)
        }

        let arguments = CommandLine.arguments
        guard
            arguments.count == 2,
            let command = Command(rawValue: arguments[1])
        else {
            exitWithUsage()
        }

        do {
            switch command {
                case .build:
                    print("Building site")
                    try build()
                case .preview:
                    // Quit the program on interrupt (the server sometimes doesn't like stopping)
                    trap(.interrupt, action: { _ in
                        Foundation.exit(0)
                    })

                    // Build the site
                    print("Building site")
                    try build()

                    // Rebuild site when any input files change
                    print("Watching file system for changes")
                    let pathsToWatch = [configuration.inputDirectory.path, configuration.templateFile?.path].compactMap { $0 }
                    try FileSystemWatcher.startWatchingForDebouncedModifications(paths: pathsToWatch, with: {
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
                    try await Server.host(configuration.outputDirectory, onPort: 8081)
            }
        } catch {
            print("Failed to \(command.rawValue) site: \(error)")
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
