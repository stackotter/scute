import Foundation

/// A protocol which plugins can conform to to influence the processing and generation of pages.
public protocol Plugin {
    associatedtype Configuration
    associatedtype Context

    /// A unique name for the plugin.
    static var name: String { get }

    /// The plugin's user-defined configuration.
    var configuration: Configuration { get }

    /// Setups up the plugin in a specified output directory. The plugin can return a context which is passed to each call to ``process(_:_:)-8yymq`` and ``process(_:_:site:)-3w37a``.
    func setup(in directory: URL) throws -> Context

    /// Called once for each page before ``process(_:_:site:)-7wjm6`` is called. Should be used for transforming each page in isolation.
    func process(_ page: inout Page, _ context: Context) throws

    /// Called after ``process(_:_:)-5av6z`` has been called once for each page. Allows for batch processing and generation of new pages.
    func process(_ pages: inout [Page], _ context: Context, site: Site.Configuration) throws
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

public extension Plugin {
    func process(_ page: inout Page, _ context: Context) throws {}
    func process(_ pages: inout [Page], _ context: Context, site: Site.Configuration) throws {}
}
