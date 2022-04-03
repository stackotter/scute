protocol Plugin {
    associatedtype Context

    var context: Context { get }

    func process(_ article: inout Article) throws
}

extension Plugin where Context == Void {
    var context: Void {
        Void()
    }
}
