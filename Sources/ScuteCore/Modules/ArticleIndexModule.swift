import Foundation
import SwiftSoup

public enum ArticleIndexModuleError: LocalizedError {
    case articleMissingTitle(URL)
    case articleMissingYearMonthDay(URL)
    case invalidDate(day: Int, month: Int, year: Int)
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
        let reverseSort = parameters.reverse ?? false

        let articlesDirectory = configuration.inputDirectory.appendingPathComponent(parameters.path)

        let articleFiles = try FileManager.default
            .contentsOfDirectory(at: articlesDirectory, includingPropertiesForKeys: nil)
            .filter { file in
                file.pathExtension == "md" && file.lastPathComponent != "index.md"
            }

        let documents = try articleFiles.map { file in
            (file, try Markdown.document(from: try String(contentsOf: file)))
        }

        var articles: [(file: URL, title: String, date: Date)] = []
        for (file, document) in documents {
            guard let title = document.title else {
                throw ArticleIndexModuleError.articleMissingTitle(file)
            }

            guard
                let year = document.metadata["year"].flatMap({ Int($0) }),
                let month = document.metadata["month"].flatMap({ Int($0) }),
                let day = document.metadata["day"].flatMap({ Int($0) })
            else {
                throw ArticleIndexModuleError.articleMissingYearMonthDay(file)
            }

            var dateComponents = DateComponents()
            dateComponents.year = year
            dateComponents.month = month
            dateComponents.day = day
            dateComponents.calendar = .current

            guard let date = dateComponents.date else {
                throw ArticleIndexModuleError.invalidDate(day: day, month: month, year: year)
            }

            articles.append((file: file, title: title, date: date))
        }

        articles = articles.sorted { first, second in
            first.date.compare(second.date) == .orderedAscending
        }

        if reverseSort {
            articles = articles.reversed()
        }

        let html = "<ul>" + articles.map { (file, title, date) in
            let link = parameters.path + "/" + file.deletingPathExtension().lastPathComponent
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("dd/MM/yyyy")
            let dateString = formatter.string(from: date)
            return "<li><a href=\"\(link)\">\(title)</a> — <i>\(dateString)</i></li>"
        }.joined(separator: "") + "</ul>"

        // Update the element
        try moduleElement.html(html)
        try moduleElement.tagName("p")
        try moduleElement.attr("class", "-article-index")
    }
}
