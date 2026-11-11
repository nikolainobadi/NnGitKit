import NnGitKit

/// Throws `UnexpectedCommand` for any command it wasn't given a result for, rather than returning
/// empty output: an empty string reads as a real answer, so comparisons between two unregistered
/// commands would silently pass.
public struct MockGitCommandRunner: GitCommandRunner {
    private let gitResults: [GitResult]
    private let gitHubResults: [GitHubResult]

    public init(gitResults: [GitResult], gitHubResults: [GitHubResult]) {
        self.gitResults = gitResults
        self.gitHubResults = gitHubResults
    }
}

// MARK: - GitCommandRunner
extension MockGitCommandRunner {
    public func runGit(_ command: GitCommand, at path: String) throws -> GitCommandOutput {
        guard let result = gitResults.first(where: { $0.command == command && $0.path == path }) else {
            throw UnexpectedCommand.git(command: command, path: path)
        }

        return result.output
    }

    public func runGitHub(_ command: GitHubCommand, at path: String?) throws -> GitCommandOutput {
        guard let result = gitHubResults.first(where: { $0.command == command && $0.path == path }) else {
            throw UnexpectedCommand.gitHub(command: command, path: path)
        }

        return result.output
    }
}

// MARK: - Dependencies
extension MockGitCommandRunner {
    public struct GitResult: Sendable {
        public let command: GitCommand
        public let path: String
        public let output: GitCommandOutput

        public init(command: GitCommand, path: String, output: GitCommandOutput) {
            self.command = command
            self.path = path
            self.output = output
        }
    }

    public struct GitHubResult: Sendable {
        public let command: GitHubCommand
        public let path: String?
        public let output: GitCommandOutput

        public init(command: GitHubCommand, path: String?, output: GitCommandOutput) {
            self.command = command
            self.path = path
            self.output = output
        }
    }

    public enum UnexpectedCommand: Error, Equatable {
        case git(command: GitCommand, path: String)
        case gitHub(command: GitHubCommand, path: String?)
    }
}
