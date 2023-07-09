import ArgumentParser
import Foundation
import ScuteCore

struct CreateCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new scute project."
    )

    @Argument(help: "The name for the new project")
    var name: String

    @Option(
        name: .shortAndLong,
        help: "The directory to create for the project. Defaults to the supplied project name.",
        transform: URL.init(fileURLWithPath:))
    var directory: URL?

    @Flag(help: "Creates a vercel.json with the configuration required to host with vercel.")
    var vercel = false

    func run() throws {
        let directory = directory ?? URL(fileURLWithPath: name)
        guard !directory.isExistingDirectory else {
            throw ScuteError.newProjectDirectoryAlreadyExists(directory.relativePath)
        }

        do {
            // Create root directory
            try FileManager.default.createDirectory(
                at: directory, withIntermediateDirectories: true
            )

            // Create configuration
            let configuration = Configuration.default(usingName: name)
            try configuration.write(toDirectory: directory)

            // Create input directory
            let inputDirectory = configuration.inputDirectory(usingBase: directory)
            try FileManager.default.createDirectory(
                at: inputDirectory, withIntermediateDirectories: true
            )

            // Create template file
            let templateFile = configuration.templateFile(usingBase: directory)
            try SkeletonProject.pageTemplate.write(
                to: templateFile, atomically: false, encoding: .utf8)

            // Creaste css/page.css
            let cssDirectory = inputDirectory.appendingPathComponent("css")
            try FileManager.default.createDirectory(
                at: cssDirectory, withIntermediateDirectories: true
            )
            let pageCSSFile = cssDirectory.appendingPathComponent("page.css")
            try SkeletonProject.pageCSS.write(
                to: pageCSSFile, atomically: false, encoding: .utf8
            )

            // Create index.md
            let indexFile = inputDirectory.appendingPathComponent("index.md")
            try SkeletonProject.index.write(to: indexFile, atomically: false, encoding: .utf8)

            // Create contact.md
            let contactFile = inputDirectory.appendingPathComponent("contact.md")
            try SkeletonProject.contact.write(to: contactFile, atomically: false, encoding: .utf8)

            // Create blog/index.md
            let blogDirectory = inputDirectory.appendingPathComponent("blog")
            try FileManager.default.createDirectory(
                at: blogDirectory, withIntermediateDirectories: true
            )
            let blogIndexFile = blogDirectory.appendingPathComponent("index.md")
            try SkeletonProject.blog.write(to: blogIndexFile, atomically: false, encoding: .utf8)

            // Create blog/first-post.md
            let firstBlogPostFile = blogDirectory.appendingPathComponent("first-post.md")
            try SkeletonProject.firstPost(date: Date.now).write(
                to: firstBlogPostFile, atomically: false, encoding: .utf8
            )

            // If the user wants, create a vercel configuration file
            if vercel {
                let vercelJSONFile = directory.appendingPathComponent("vercel.json")
                try SkeletonProject.vercelJSON.write(
                    to: vercelJSONFile, atomically: false, encoding: .utf8
                )
            }
        } catch {
            // Attempt to clean up on error
            try? FileManager.default.removeItem(at: directory)
            throw error
        }

        print(
            """
            Now that you're the proud owner of a new site, go check it out!

            ```
            cd \(directory.relativePath)
            scute
            ```
            """
        )
    }
}
