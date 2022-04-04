import Foundation
import FlyingFox

public enum Server {
    public static func host(_ directory: URL, onPort port: UInt16) async throws {
        // Host a server
        let server = HTTPServer(port: port)

        await server.appendRoute("GET *") { request in
            func fileToResponse(_ file: URL) -> HTTPResponse {
                do {
                    let data = try Data(contentsOf: file)
                    return HTTPResponse(version: .http11, statusCode: .ok, headers: [:], body: data)
                } catch {
                    return HTTPResponse(statusCode: .internalServerError)
                }
            }

            // Attempt to avoid path traversal
            let path = request.path
            if path.contains("..") {
                return HTTPResponse(statusCode: .notFound)
            }

            // If the path corresponds to a non-html file, the file is returned
            // If the path + '.html' corresponds to an html file which isn't 'index.html', the html file is returned
            // If the path corresponds to a directory and 'index.html' exists within that directory, the 'index.html' file is returned
            // Otherwise, a file not found status code is returned
            let file = directory.appendingPathComponent(path)
            if file.lastPathExtension != "html" && FileManager.default.itemExists(at: file, withType: .file) {
                return fileToResponse(file)
            } else if file.lastPathExtension != "html" && FileManager.default.itemExists(at: file.appendingPathExtension("html"), withType: .file) && file.lastPathComponent != "index" {
                return fileToResponse(file.appendingPathExtension("html"))
            } else if FileManager.default.itemExists(at: file, withType: .directory) && FileManager.default.itemExists(at: file.appendingPathComponent("index.html"), withType: .file) {
                return fileToResponse(file.appendingPathComponent("index.html"))
            }
            return HTTPResponse(statusCode: .notFound)
        }

        print("Listening at http://127.0.0.1:\(port)/")
        try await server.start()
    }
}
