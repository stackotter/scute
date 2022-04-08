import Foundation

extension Page {
    public enum Stylesheet: Equatable, Hashable {
        case external(url: URL)
        case selfHosted(path: String)
        case inline(content: String)

        public var html: String {
            switch self {
                case .external(let url):
                    return #"<link rel="stylesheet" href="\#(url.absoluteString)"/>"#
                case .selfHosted(let path):
                    return #"<link rel="stylesheet" href="\#(path)"/>"#
                case .inline(let content):
                    return #"<style>\#(content)</style>"#
            }
        }
    }
}
