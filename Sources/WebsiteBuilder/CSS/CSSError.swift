import Foundation

enum CSSError: LocalizedError {
    case failedToRemoveComments(Error)
    case failedToParseDocument(Error)
}
