import Foundation
import SwiftSoup

public enum ArticleIndexModuleError: LocalizedError {
    case articleMissingTitle(URL)
    case articleMissingDate(URL)
}

/// A module that creates a simple index of all pages at a specific path.
public struct ArticleIndexModule: Module {
    public static var name = "ArticleIndex"

    public var configuration: Configuration

    public struct Configuration {
        public var inputDirectory: URL

        public init(inputDirectory: URL) {
            self.inputDirectory = inputDirectory
        }
    }

    public struct Parameters: Codable {
        public var path: String
        public var reverse: Bool?
    }

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    public func render(moduleElement: Element, with parameters: Parameters, page: Page) throws {
        let articlesDirectory = configuration.inputDirectory.appendingPathComponent(parameters.path)

        let articleFiles = try FileManager.default
            .contentsOfDirectory(at: articlesDirectory, includingPropertiesForKeys: nil)
            .filter { file in
                file.pathExtension == "md" && file.lastPathComponent != "index.md"
            }

        let documents = try articleFiles.map { file in
            (file, try Markdown.document(from: try String(contentsOf: file)))
        }

        var articles: [(file: URL, title: String, date: String)] = []
        for (file, document) in documents {
            guard let title = document.title else {
                throw ArticleIndexModuleError.articleMissingTitle(file)
            }

//            guard let date = document.metadata["date"] else {
//                throw ArticleIndexModuleError.articleMissingDate(file)
//            }
            let date = ""

            articles.append((file: file, title: title, date: date))
        }

        let html = "<ul>" + articles.map { (file, title, date) in
            let link = parameters.path + "/" + file.deletingPathExtension().lastPathComponent
            return "<li><a href=\"\(link)\">\(title)</a></li>"
        }.joined(separator: "") + "</ul>"

        // Update the element
        try moduleElement.html(html)
        try moduleElement.tagName("p")
        try moduleElement.attr("class", "-article-index")
    }
}
