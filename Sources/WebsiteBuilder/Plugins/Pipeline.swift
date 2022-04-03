import Foundation

struct Pipeline {
    let rootDirectory: URL

    private var processors: [(inout Page) throws -> Void] = []

    init(toProcess directory: URL) {
        rootDirectory = directory
    }

    mutating func append<T: Plugin>(_ plugin: T) throws {
        let context = try plugin.setup(in: rootDirectory)
        processors.append({ page in
            try plugin.process(&page, context)
        })
    }

    func processDirectory(_ directory: URL) throws {
        // Locate all markdown files
        guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil) else {
            print("Failed to enumerate markdown files")
            Foundation.exit(1)
        }

        var markdownFiles: [URL] = []
        for case let file as URL in enumerator where file.pathExtension == "md" {
            markdownFiles.append(file)
        }

        // Convert markdown files to html
        for markdownFile in markdownFiles {
            let outputFile = markdownFile.deletingPathExtension().appendingPathExtension("html")
            try convertMarkdownFile(markdownFile, outputFile)

            // Delete the markdown file from the output directory
            try FileManager.default.removeItem(at: markdownFile)
        }
    }

    func process(_ page: inout Page) throws {
        for processor in processors {
            try processor(&page)
        }
    }

    func convertMarkdownFile(_ inputFile: URL, _ outputFile: URL) throws {
        var page = try Page.fromMarkdownFile(at: inputFile)

        try process(&page)

        let html = page.toHTML()
        try html.write(to: outputFile, atomically: false, encoding: .utf8)
    }
}
