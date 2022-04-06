import Foundation

public enum PipelineError: LocalizedError {
    case failedToEnumerateInputDirectory
    case failedToProcessPage(Error)
}

public struct Pipeline {
    public let configuration: Site.Configuration

    private var plugins: [(_ outputDirectory: URL) throws -> ((inout Page) throws -> Void)] = []

    public init(_ configuration: Site.Configuration) {
        self.configuration = configuration
    }

    public func buildSite() throws {
        let start = CFAbsoluteTimeGetCurrent()

        // Delete the output directory
        try? FileManager.default.removeItem(at: configuration.outputDirectory)

        // Create the basic structure of the output directory
        try FileManager.default.createDirectory(at: configuration.outputDirectory.appendingPathComponent("css"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: configuration.outputDirectory.appendingPathComponent("js"), withIntermediateDirectories: true)

        let processors = try plugins.map { try $0(configuration.outputDirectory) }

        // Enumerate the input directory
        guard let enumerator = FileManager.default.enumerator(atPath: configuration.inputDirectory.path) else {
            print("Failed to enumerate input files")
            throw PipelineError.failedToEnumerateInputDirectory
        }

        // Build all input files
        for case let relativePath as String in enumerator {
            let inputFile = configuration.inputDirectory.appendingPathComponent(relativePath)
            let outputFile = configuration.outputDirectory.appendingPathComponent(relativePath)

            // If it's a directory, just create it and move on
            if inputFile.hasDirectoryPath {
                try FileManager.default.createDirectory(at: outputFile, withIntermediateDirectories: true)
                continue
            }

            // Skip the page template file
            if inputFile == configuration.templateFile {
                continue
            }

            // If its a file, render it if it's markdown, otherwise just copy it
            if inputFile.pathExtension == "md" {
                let outputFile = outputFile.deletingPathExtension().appendingPathExtension("html")

                var page = try Page.fromMarkdownFile(at: inputFile, forSite: configuration)
                try process(&page, processors: processors)

                let html = try page.toHTML()
                try html.write(
                    to: outputFile,
                    atomically: true,
                    encoding: .utf8
                )
            } else {
                try FileManager.default.copyItem(at: inputFile, to: outputFile)
            }
        }

        let elapsed = String(format: "%.02fms", (CFAbsoluteTimeGetCurrent() - start) * 1000)
        print("Built site in \(elapsed)")
    }

    public mutating func append<T: Plugin>(_ plugin: T) throws {
        plugins.append { (outputDirectory: URL) throws -> ((inout Page) throws -> Void) in
            let context = try plugin.setup(in: outputDirectory)
            return { (page: inout Page) throws in
                try plugin.process(&page, context)
            }
        }
    }

    private func process(_ page: inout Page, processors: [(inout Page) throws -> Void]) throws {
        for processor in processors {
            do {
                try processor(&page)
            } catch {
                throw PipelineError.failedToProcessPage(error)
            }
        }
    }
}
