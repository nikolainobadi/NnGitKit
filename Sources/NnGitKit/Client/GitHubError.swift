import Foundation

public enum GitHubError: Error, Equatable, Sendable {
    case requestFailed(endpoint: String, output: String)
    case commandFailed(command: GitHubCommand, exitCode: Int32, output: String)
    case unexpectedOutput(command: GitHubCommand, output: String)
}

// MARK: - LocalizedError
extension GitHubError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .requestFailed(let endpoint, let output):
            return "Couldn't read \(endpoint) from GitHub, so nothing was changed. Check `gh auth status` and your network connection, then run again.\n\(output)"
        case .commandFailed(let command, _, let output):
            return "`gh \(command.arguments.joined(separator: " "))` failed. Check `gh auth status` and your network connection, then run again.\n\(output)"
        case .unexpectedOutput(let command, let output):
            return "`gh \(command.arguments.joined(separator: " "))` returned \"\(output)\", which isn't a recognized response, so nothing was changed. Check that your gh is up to date, then run again."
        }
    }
}
