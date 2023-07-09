import Foundation

enum ScuteError: LocalizedError {
    case failedToLoadConfiguration(Error)
    case missingConfigurationFile(URL)
    case missingInputDirectory(String)
    case missingOutputDirectory(String)
    case missingTemplateFile(String)

    var errorDescription: String? {
        // TODO: Incorporate relative file/directory paths into config file error messages
        switch self {
            case .failedToLoadConfiguration(let error):
                return "Failed to load configuration file at 'Scute.toml': \(error)"
            case .missingConfigurationFile:
                return "Expected configuration file to be at 'Scute.toml'"
            case .missingInputDirectory(let path):
                return "Missing input directory at '\(path)'"
            case .missingOutputDirectory(let path):
                return "Missing output directory at '\(path)'"
            case .missingTemplateFile(let path):
                return "Missing template file at '\(path)'"
        }
    }
}
