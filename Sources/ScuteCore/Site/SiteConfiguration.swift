import Foundation

extension Site {
    public struct Configuration {
        public var name: String
        public var inputDirectory: URL
        public var outputDirectory: URL
        public var templateFile: URL

        public init(name: String, inputDirectory: URL, outputDirectory: URL, templateFile: URL) {
            self.name = name
            self.inputDirectory = inputDirectory
            self.outputDirectory = outputDirectory
            self.templateFile = templateFile
        }
    }
}
