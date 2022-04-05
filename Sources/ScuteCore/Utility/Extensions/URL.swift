import Foundation

extension URL {
    var lastPathExtension: String {
        return pathExtension.split(separator: ".").last.map(String.init) ?? pathExtension
    }
}
