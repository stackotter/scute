import Foundation

extension Optional where Wrapped == URL {
    var orCWD: URL {
        self ?? URL(fileURLWithPath: ".")
    }
}

extension URL {
    var isExistingFile: Bool {
        var isDirectory = ObjCBool(false)
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
            && !isDirectory.boolValue
    }

    var isExistingDirectory: Bool {
        var isDirectory = ObjCBool(false)
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
            && isDirectory.boolValue
    }
}
