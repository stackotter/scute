import Foundation
import ScuteCore
import TOMLKit

struct Configuration: Codable {
    static let currentConfigVersion = 1

    static let defaultInputDirectoryPath = "src"
    static let defaultOutputDirectoryPath = "build"
    static let defaultTemplateFilePath = defaultInputDirectoryPath + "/_template.html"

    static let defaultSyntaxTheme = "atom-one-dark"

    static let defaultConfigurationFilePath = "Scute.toml"

    var configVersion: Int

    var name: String
    var inputDirectoryPath: String?
    var outputDirectoryPath: String?
    var templateFilePath: String?
    var syntaxTheme: String?

    var syntaxThemeOrDefault: String {
        syntaxTheme ?? Self.defaultSyntaxTheme
    }

    enum CodingKeys: String, CodingKey {
        case configVersion = "config_version"
        case name
        case inputDirectoryPath = "input"
        case outputDirectoryPath = "output"
        case templateFilePath = "page_template"
        case syntaxTheme = "syntax_theme"
    }

    static func `default`(usingName name: String) -> Configuration {
        Configuration(
            configVersion: Self.currentConfigVersion,
            name: name,
            inputDirectoryPath: nil,
            outputDirectoryPath: nil,
            templateFilePath: nil,
            syntaxTheme: nil
        )
    }

    static func load(from file: URL, inProject directory: URL) throws -> Configuration {
        if !FileManager.default.fileExists(atPath: file.path) {
            throw ScuteError.missingConfigurationFile(file)
        }

        do {
            let contents = try String(contentsOf: file)
            let tomlTable = try TOMLTable(string: contents)

            // Ensure that config version is supported
            let version = tomlTable["config_version"]
            guard let version = version?.int, version <= Self.currentConfigVersion else {
                throw ScuteError.unsupportedConfigurationFileVersion(
                    version?.tomlValue.debugDescription
                )
            }

            let configuration = try TOMLDecoder(strictDecoding: true).decode(
                Configuration.self, from: tomlTable
            )
            try configuration.validate(with: directory)
            return configuration
        } catch {
            if error is ScuteError {
                throw error
            } else {
                throw ScuteError.failedToLoadConfiguration(error)
            }
        }
    }

    static func load(fromDirectory directory: URL) throws -> Configuration {
        try load(
            from: directory.appendingPathComponent(defaultConfigurationFilePath),
            inProject: directory
        )
    }

    func write(to file: URL) throws {
        do {
            let toml = try TOMLEncoder().encode(self) + "\n"
            try toml.write(to: file, atomically: false, encoding: .utf8)
        } catch {
            throw ScuteError.failedToWriteConfigurationToFile(file, error)
        }
    }

    func write(toDirectory directory: URL) throws {
        try write(to: directory.appendingPathComponent(Self.defaultConfigurationFilePath))
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

    func toSite(with directory: URL) throws -> Site {
        var site = Site(toSiteConfiguration(forSiteIn: directory))
        try site.addDefaultPlugins(syntaxTheme: syntaxThemeOrDefault)
        return site
    }

    func validate(with directory: URL) throws {
        guard inputDirectory(usingBase: directory).isExistingDirectory else {
            throw ScuteError.missingInputDirectory(
                inputDirectoryPath ?? Self.defaultInputDirectoryPath)
        }

        guard templateFile(usingBase: directory).isExistingFile else {
            throw ScuteError.missingTemplateFile(
                templateFilePath ?? Self.defaultTemplateFilePath)
        }
    }
}
