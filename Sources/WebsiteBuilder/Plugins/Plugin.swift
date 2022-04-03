import Foundation

protocol Plugin {
    associatedtype Configuration
    associatedtype Context

    var configuration: Configuration { get }

    func setup(in directory: URL) throws -> Context

    func process(_ page: inout Page, _ context: Context) throws
}

extension Plugin where Configuration == Void {
    var configuration: Void {
        Void()
    }
}

extension Plugin where Context == Void {
    func setup(in directory: URL) throws -> Void {
        return Void()
    }
}
