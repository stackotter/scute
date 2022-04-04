import Foundation
import SwiftSoup
import Parsing

public enum ModuleRendererPluginError: LocalizedError {
    case invalidUTF8InModuleProperties(module: String)
    case noSuchModule(String)
}

public struct ModuleRendererPlugin: Plugin {
    public static let moduleParser = Parse {
        OneOf {
            Parse {
                Prefix { $0 != "{" }
                    .map(String.init)
                Rest<Substring>()
                    .map(String.init)
                    .map(Optional.some)
            }
            
            Rest().map { name in
                (String(name), Optional<String>.none)
            }
        }
    }

    public var configuration: Configuration

    public struct Configuration {
        private(set) var renderers: [String: (_ element: Element, _ parameters: String, _ page: Page) throws -> Void] = [:]

        public init() {}

        public mutating func addModule<T: Module>(_ module: T) {
            renderers[T.name] = { (element: Element, parametersString: String, page: Page) in
                guard let data = parametersString.data(using: .utf8) else {
                    throw ModuleRendererPluginError.invalidUTF8InModuleProperties(module: T.name)
                }
                let parameters = try JSONDecoder().decode(T.Parameters.self, from: data)
                try module.render(moduleElement: element, with: parameters, page: page)
            }
        }
    }

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    public func process(_ page: inout Page, _ context: Void) throws {
        let document = try SwiftSoup.parse(page.content)
        let moduleElements = try document.select("module")

        for moduleElement in moduleElements {
            let content = try moduleElement.html()
            let (name, parameters) = try Self.moduleParser.parse(content)

            guard let renderer = configuration.renderers[name] else {
                throw ModuleRendererPluginError.noSuchModule(name)
            }
            try renderer(moduleElement, parameters ?? "{}", page)
        }

        let html = try document.html()
        page.content = html
    }
}
