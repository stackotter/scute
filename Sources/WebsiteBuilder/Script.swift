enum Script {
    case hosted(url: String)
    case inline(contents: String)

    var html: String {
        switch self {
            case .hosted(let url):
                return #"<script src="\#(url)"></script>"#
            case .inline(let content):
                return #"<script>\#(content)</script>"#
        }
    }
}
