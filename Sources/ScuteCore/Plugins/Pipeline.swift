import Foundation

public enum PipelineError: LocalizedError {
    case failedToEnumerateInputDirectory
    case failedToProcessPage(Error)
    case failedToProcessPages(Error)
}

public struct Pipeline {
    public let configuration: Site.Configuration

    private var pluginInitializers: [(_ outputDirectory: URL) throws -> AnyPlugin] = []

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

        let plugins = try pluginInitializers.map { try $0(configuration.outputDirectory) }

        // Enumerate the input directory
        guard let enumerator = FileManager.default.enumerator(atPath: configuration.inputDirectory.path) else {
            print("Failed to enumerate input files")
            throw PipelineError.failedToEnumerateInputDirectory
        }

        // Build all input files
        var pages: [(page: Page, outputFile: URL)] = []
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
                let page = try Page.fromMarkdownFile(at: inputFile, forSite: configuration)
                pages.append((page: page, outputFile: outputFile))
            } else {
                try FileManager.default.copyItem(at: inputFile, to: outputFile)
            }
        }

        // Post-process the pages and output them to disk
        var postProcessedPages = pages.map(\.page)
        try process(&postProcessedPages, with: plugins)
        let outputFiles = pages.map(\.outputFile)
        for (page, outputFile) in zip(postProcessedPages, outputFiles) {
            let html = try page.toHTML()
            try html.write(
                to: outputFile,
                atomically: true,
                encoding: .utf8
            )
        }

        let elapsed = String(format: "%.02fms", (CFAbsoluteTimeGetCurrent() - start) * 1000)
        print("Built site in \(elapsed)")
    }

    public mutating func append<T: Plugin>(_ plugin: T) throws {
        pluginInitializers.append { (outputDirectory: URL) throws -> AnyPlugin in
            let context = try plugin.setup(in: outputDirectory)
            return plugin.toAnyPlugin(context)
        }
    }

    private func process(_ page: inout Page, with plugins: [AnyPlugin]) throws {
        for plugin in plugins {
            do {
                try plugin.processPage(&page)
            } catch {
                throw PipelineError.failedToProcessPage(error)
            }
        }
    }

    private func process(_ pages: inout [Page], with plugins: [AnyPlugin]) throws {
        for plugin in plugins {
            for i in 0..<pages.count {
                try plugin.processPage(&pages[i])
            }
            
            do {
                try plugin.processPages(&pages, configuration)
            } catch {
                throw PipelineError.failedToProcessPages(error)
            }
        }
    }
}
