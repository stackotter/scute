import Foundation

public protocol Plugin {
    associatedtype Configuration
    associatedtype Context

    var configuration: Configuration { get }

    func setup(in directory: URL) throws -> Context

    func process(_ page: inout Page, _ context: Context) throws
}

public extension Plugin where Configuration == Void {
    var configuration: Void {
        Void()
    }
}

public extension Plugin where Context == Void {
    func setup(in directory: URL) throws -> Void {
        return Void()
    }
}
