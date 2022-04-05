import Foundation

public struct PageTemplatePlugin: Plugin {
    public static var name = "page_template"

    public var configuration: Configuration

    public struct Configuration {
        public var templateDirectory: URL

        public init(templateDirectory: URL) {
            self.templateDirectory = templateDirectory
        }
    }

    public struct Context {
        public var templateContents: String
    }

    public init(configuration: PageTemplatePlugin.Configuration) {
        self.configuration = configuration
    }

    public func setup(in directory: URL) throws -> Context {
        // Copy template's css files
        let cssDirectoryContents = try FileManager.default.contentsOfDirectory(
            at: configuration.templateDirectory.appendingPathComponent("css"),
            includingPropertiesForKeys: nil
        )

        for item in cssDirectoryContents {
            try FileManager.default.copyItem(at: item, to: directory.appendingPathComponent("css").appendingPathComponent(item.lastPathComponent))
        }

        // Get the contents of the template
        let templateFile = configuration.templateDirectory.appendingPathComponent("page.html")
        let templateContents = try String(contentsOf: templateFile)

        return Context(templateContents: templateContents)
    }

    public func process(_ page: inout Page, _ context: Context) throws {
        var content = context.templateContents
        content = content.replacingOccurrences(of: "{content}", with: page.content)
        content = content.replacingOccurrences(of: "{title}", with: "stackotter")
        page.content = content
    }
}
