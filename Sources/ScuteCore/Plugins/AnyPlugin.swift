import Foundation

struct AnyPlugin {
    var name: String
    var processPage: (inout Page) throws -> Void
    var processPages: (inout [Page], Site.Configuration) throws -> Void
}

extension Plugin {
    func toAnyPlugin(_ context: Context) -> AnyPlugin {
        return AnyPlugin(
            name: Self.name,
            processPage: { (page: inout Page) throws -> Void in
                try process(&page, context)
            },
            processPages: { (pages: inout [Page], site: Site.Configuration) throws -> Void in
                try process(&pages, context, site: site)
            }
        )
    }
}
