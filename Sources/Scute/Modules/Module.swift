import SwiftSoup

public protocol Module {
    associatedtype Configuration
    associatedtype Parameters: Codable

    static var name: String { get }

    var configuration: Configuration { get }

    func render(moduleElement: Element, with parameters: Parameters, page: Page) throws
}

public extension Module where Configuration == Void {
    var configuration: Void {
        Void()
    }
}
