import Foundation
import FlyingFox

@main
enum Scute {
    static let inputDirectory = URL(fileURLWithPath: "src")
    static let outputDirectory = URL(fileURLWithPath: "out")
    static let templateDirectory = URL(fileURLWithPath: "template")

    static func build() throws {
        let start = CFAbsoluteTimeGetCurrent()

        // Clear the output directory
        try? FileManager.default.removeItem(at: outputDirectory)

        // Copy the input files to the output directory
        try FileManager.default.copyItem(at: inputDirectory, to: outputDirectory)

        // TODO: make a better way of doing this
        try FileManager.default.createDirectory(at: outputDirectory.appendingPathComponent("css"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outputDirectory.appendingPathComponent("js"), withIntermediateDirectories: true)

        // Create page processing pipeline
        var pipeline = Pipeline(toProcess: outputDirectory)
        try pipeline.append(SyntaxHighlightingPlugin(configuration: .init(theme: "atom-one-dark")))
        try pipeline.append(GitHubMarkdownThemePlugin(configuration: .init(theme: .light)))
        try pipeline.append(HeadingIDPlugin())
        try pipeline.append(PageTemplatePlugin(configuration: .init(templateDirectory: templateDirectory)))

        // Processes the files in the output directory
        try pipeline.processDirectory(outputDirectory)

        let elapsed = String(format: "%.02fms", (CFAbsoluteTimeGetCurrent() - start) * 1000)
        print("Built site in \(elapsed)")
    }

    static func main() async throws {
        print("Building site")
        try build()

        // Quit the server on interrupt
        trap(.interrupt, action: { _ in
            Foundation.exit(1)
        })

        final class Debouncer: @unchecked Sendable {
            var latestEvent: FileSystemWatcher.EventID? = nil
        }

        let debouncer = Debouncer()

        let queue = DispatchQueue(label: "site-rebuilder")

        print("Watching file system for changes")
        try FileSystemWatcher.startWatching(paths: [inputDirectory.path, templateDirectory.path], with: { event in
            if event.flags?.contains(.itemCloned) == true || event.flags?.contains(.historyDone) == true {
                return
            }

            // Store the latest event id and then wait 200 milliseconds to debounce
            queue.sync {
                debouncer.latestEvent = event.id
            }
            queue.asyncAfter(deadline: .now() + .milliseconds(200)) {
                if debouncer.latestEvent == event.id {
                    do {
                        print("Detected changes, rebuilding site")
                        try build()
                        print("Successfully rebuilt site")
                    } catch {
                        print("Failed to rebuild site")
                    }
                }
            }
        }, errorHandler: { error in
            print("Error processing file system event: \(error)")
        })

        // Host a server
        let server = HTTPServer(port: 80)
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

            let file = outputDirectory.appendingPathComponent(path)
            if file.pathExtension != "html" && FileManager.default.itemExists(at: file, withType: .file) {
                return fileToResponse(file)
            } else if file.pathExtension == "" && FileManager.default.itemExists(at: file.appendingPathExtension("html"), withType: .file) {
                return fileToResponse(file.appendingPathExtension("html"))
            } else if FileManager.default.itemExists(at: file, withType: .directory) && FileManager.default.itemExists(at: file.appendingPathComponent("index.html"), withType: .file) {
                return fileToResponse(file.appendingPathComponent("index.html"))
            }
            return HTTPResponse(statusCode: .notFound)
        }

        print("Listening at http://127.0.0.1:80/")
        try await server.start()
    }
}
