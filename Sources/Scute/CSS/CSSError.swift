import Foundation

public enum CSSError: LocalizedError {
    case failedToRemoveComments(Error)
    case failedToParseDocument(Error)
}
