import Foundation

/// All processes that have been created using `Process.create(_:arguments:directory:pipe:)`.
///
/// If the program is killed, all processes in this array are terminated before the program exits.
var processes: [Process] = []

enum ProcessError: LocalizedError {
    case nonZeroExitStatus(Int)
}

extension Process {
    /// Runs the process and waits for it to complete.
    /// - Returns: Returns a failure if the process has a non-zero exit status of fails to run.
    func runAndWait() throws {
        try run()

        waitUntilExit()

        let exitStatus = Int(terminationStatus)
        if exitStatus != 0 {
            throw ProcessError.nonZeroExitStatus(exitStatus)
        }
    }

    /// Creates a new process (but doesn't run it).
    /// - Parameters:
    ///   - tool: The tool.
    ///   - arguments: The tool's arguments.
    ///   - directory: The directory to run the command in. Defaults to the current directory.
    ///   - pipe: The pipe for the process's stdout and stderr. Defaults to `nil`.
    /// - Returns: The new process.
    static func create(_ tool: String, arguments: [String] = [], directory: URL? = nil) -> Process {
        let process = Process()

        process.currentDirectoryURL = directory?.standardizedFileURL.absoluteURL
        process.launchPath = tool
        process.arguments = arguments

        processes.append(process)

        return process
    }
}
