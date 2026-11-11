import Foundation

public enum GitError: Error, Sendable {
    case commandFailed(command: GitCommand, exitCode: Int32, output: String)
    case unreadableOutput(command: GitCommand, output: String)
}

// MARK: - LocalizedError
extension GitError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .commandFailed(let command, let exitCode, let output):
            let detail = output.isEmpty ? "" : "\n\(output)"

            return "`git \(command.commandArguments.joined(separator: " "))` failed with exit code \(exitCode).\(detail)"
        case .unreadableOutput(let command, let output):
            return "Couldn't read the output of `git \(command.commandArguments.joined(separator: " "))`:\n\(output)"
        }
    }
}
