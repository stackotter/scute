import Foundation
import ScuteCore
import TOMLKit

struct Configuration: Codable {
    static let currentConfigVersion = 1

    static let defaultInputDirectoryPath = "src"
    static let defaultOutputDirectoryPath = "build"
    static let defaultTemplateFilePath = defaultInputDirectoryPath + "/_template.html"

    static let defaultConfigurationFilePath = "Scute.toml"

    var configVersion: Int

    var name: String
    var inputDirectoryPath: String?
    var outputDirectoryPath: String?
    var templateFilePath: String?

    enum CodingKeys: String, CodingKey {
        case configVersion = "config_version"
        case name
        case inputDirectoryPath = "input"
        case outputDirectoryPath = "output"
        case templateFilePath = "page_template"
    }

    func `default`(usingName name: String) -> Configuration {
        Configuration(
            configVersion: Self.currentConfigVersion,
            name: name,
            inputDirectoryPath: nil,
            outputDirectoryPath: nil,
            templateFilePath: nil
        )
    }

    func inputDirectory(usingBase base: URL) -> URL {
        base.appendingPathComponent(
            inputDirectoryPath ?? Self.defaultInputDirectoryPath)
    }

    func outputDirectory(usingBase base: URL) -> URL {
        base.appendingPathComponent(
            outputDirectoryPath ?? Self.defaultOutputDirectoryPath)
    }

    func templateFile(usingBase base: URL) -> URL {
        base.appendingPathComponent(
            templateFilePath ?? Self.defaultTemplateFilePath)
    }

    func toSiteConfiguration(forSiteIn directory: URL) -> Site.Configuration {
        Site.Configuration(
            name: name,
            inputDirectory: inputDirectory(usingBase: directory),
            outputDirectory: outputDirectory(usingBase: directory),
            templateFile: templateFile(usingBase: directory)
        )
    }

    func toSite(with directory: URL) -> Site {
        Site(toSiteConfiguration(forSiteIn: directory))
    }

    func validate(with directory: URL) throws {
        guard inputDirectory(usingBase: directory).isExistingDirectory else {
            throw ScuteError.missingInputDirectory(
                inputDirectoryPath ?? Self.defaultInputDirectoryPath)
        }

        guard outputDirectory(usingBase: directory).isExistingDirectory else {
            throw ScuteError.missingOutputDirectory(
                outputDirectoryPath ?? Self.defaultOutputDirectoryPath)
        }

        guard templateFile(usingBase: directory).isExistingFile else {
            throw ScuteError.missingTemplateFile(
                templateFilePath ?? Self.defaultTemplateFilePath)
        }
    }

    static func load(from file: URL) throws -> Configuration {
        if !FileManager.default.fileExists(atPath: file.path) {
            throw ScuteError.missingConfigurationFile(file)
        }

        do {
            let contents = try String(contentsOf: file)
            return try TOMLDecoder(strictDecoding: true).decode(Configuration.self, from: contents)
        } catch {
            throw ScuteError.failedToLoadConfiguration(error)
        }
    }

    static func load(fromDirectory directory: URL) throws -> Configuration {
        try load(from: directory.appendingPathComponent(defaultConfigurationFilePath))
    }
}
