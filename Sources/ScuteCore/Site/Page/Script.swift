public enum Script {
    case externalScript(url: String)
    case internalScript(contents: String)

    public var html: String {
        switch self {
            case .externalScript(let url):
                return #"<script src="\#(url)"></script>"#
            case .internalScript(let content):
                return #"<script>\#(content)</script>"#
        }
    }
}
