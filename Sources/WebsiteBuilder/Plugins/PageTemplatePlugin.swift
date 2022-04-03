import Foundation

struct PageTemplatePlugin: Plugin {
    var configuration: Configuration

    struct Configuration {
        var templateDirectory: URL
    }

    struct Context {
        var templateContents: String
    }

    func setup(in directory: URL) throws -> Context {
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

    func process(_ page: inout Page, _ context: Context) throws {
        var content = context.templateContents
        content = content.replacingOccurrences(of: "{content}", with: page.content)
        content = content.replacingOccurrences(of: "{title}", with: "stackotter")
        page.content = content
    }
}
