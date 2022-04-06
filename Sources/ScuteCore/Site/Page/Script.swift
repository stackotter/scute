public enum Script {
    case externalScript(url: String, shouldDefer: Bool)
    case internalScript(contents: String)

    public var html: String {
        switch self {
            case .externalScript(let url, let shouldDefer):
                return #"<script \#(shouldDefer ? "defer" : "") src="\#(url)"></script>"#
            case .internalScript(let content):
                return #"<script>\#(content)</script>"#
        }
    }
}
