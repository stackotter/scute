enum StyleSheet {
    case hosted(url: String)
    case inline(content: String)

    var html: String {
        switch self {
            case .hosted(let url):
                return #"<link rel="stylesheet" href="\#(url)"/>"#
            case .inline(let content):
                return #"<style>\#(content)</style>"#
        }
    }
}
