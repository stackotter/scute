public enum StyleSheet {
    case externalSheet(url: String)
    case internalSheet(content: String)

    public var html: String {
        switch self {
            case .externalSheet(let url):
                return #"<link rel="stylesheet" href="\#(url)"/>"#
            case .internalSheet(let content):
                return #"<style>\#(content)</style>"#
        }
    }
}
