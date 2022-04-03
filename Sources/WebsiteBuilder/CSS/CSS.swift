import Parsing

enum CSS {
    static func parseDocument(_ input: String) -> Result<Document, CSSError> {
        return removeComments(from: input)
            .flatMap { inputWithoutComments in
                parseCommentlessDocument(inputWithoutComments)
            }
    }

    static func parseCommentlessDocument(_ input: String) -> Result<Document, CSSError> {
        do {
            let blocks: [Block] = try documentParser.parse(input)
            return .success(Document(blocks: blocks))
        } catch {
            return .failure(.failedToParseDocument(error))
        }
    }

    static func removeComments(from input: String) -> Result<String, CSSError> {
        do {
            let inputWithoutComments = try commentRemovingParser.parse(input)
            return .success(inputWithoutComments)
        } catch {
            return .failure(.failedToRemoveComments(error))
        }
    }
}
