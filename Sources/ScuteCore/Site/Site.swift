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

        class Box<T> {
            var value: T

            init(_ value: T) {
                self.value = value
            }
        }

        let waitingToRebuild = Box(false)
        let rebuildQueue = DispatchQueue(label: "dev.stackotter.scute.rebuild")
        let flagQueue = DispatchQueue(label: "dev.stackotter.scute.rebuild-flag")

        try await withThrowingTaskGroup(of: Void.self) { group in
            // Watch file system for changes
            group.addTask {
                try await FileSystemWatcher.watch(
                    paths: pathsToWatch,
                    with: {
                        flagQueue.sync {
                            if waitingToRebuild.value {
                                return
                            } else {
                                waitingToRebuild.value = true
                                rebuildQueue.async {
                                    flagQueue.sync {
                                        waitingToRebuild.value = false
                                    }
                                    print("Detected changes, rebuilding site")
                                    do {
                                        try build()
                                        print("Successfully rebuilt site")
                                    } catch {
                                        print("Failed to rebuild site: \(error)")
                                    }
                                }
                            }
                        }
                    },
                    errorHandler: { error in
                        print("Error processing file system event: \(error)")
                        Foundation.exit(1)
                    }
                )
            }

            // Host the site
            group.addTask {
                try await Server.host(configuration.outputDirectory, onPort: port)
            }

            try await group.waitForAll()
        }
    }

    public mutating func addPlugin<T: Plugin>(_ plugin: T) throws {
        try pipeline.append(plugin)
    }
}
