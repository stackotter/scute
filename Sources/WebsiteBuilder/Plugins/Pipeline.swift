struct Pipeline {
    private var processors: [(inout Article) throws -> Void] = []

    mutating func append<T: Plugin>(_ plugin: T) {
        processors.append({ article in
            try plugin.process(&article)
        })
    }

    func process(_ article: inout Article) throws {
        for processor in processors {
            try processor(&article)
        }
    }
}
