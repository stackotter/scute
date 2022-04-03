import Foundation

extension Result {
    func unwrap() throws -> Success {
        switch self {
            case .success(let success):
                return success
            case .failure(let failure):
                throw failure
        }
    }
}
