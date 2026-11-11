import NnGitKit
import Synchronization

public final class RecordingGitCommandRunner: GitCommandRunner {
    private let scripted: MockGitCommandRunner
    private let calls = Mutex(Calls())

    public init(gitResults: [MockGitCommandRunner.GitResult], gitHubResults: [MockGitCommandRunner.GitHubResult]) {
        self.scripted = .init(gitResults: gitResults, gitHubResults: gitHubResults)
    }
}

// MARK: - Recorded Calls
extension RecordingGitCommandRunner {
    public var gitCalls: [GitCall] {
        return calls.withLock { $0.git }
    }

    public var gitHubCalls: [GitHubCall] {
        return calls.withLock { $0.gitHub }
    }

    public var gitCommands: [GitCommand] {
        return gitCalls.map(\.command)
    }

    public var gitHubCommands: [GitHubCommand] {
        return gitHubCalls.map(\.command)
    }
}

// MARK: - GitCommandRunner
extension RecordingGitCommandRunner {
    public func runGit(_ command: GitCommand, at path: String) throws -> GitCommandOutput {
        calls.withLock { $0.git.append(.init(command: command, path: path)) }

        return try scripted.runGit(command, at: path)
    }

    public func runGitHub(_ command: GitHubCommand, at path: String?) throws -> GitCommandOutput {
        calls.withLock { $0.gitHub.append(.init(command: command, path: path)) }

        return try scripted.runGitHub(command, at: path)
    }
}

// MARK: - Dependencies
extension RecordingGitCommandRunner {
    public struct GitCall: Sendable, Equatable {
        public let command: GitCommand
        public let path: String

        public init(command: GitCommand, path: String) {
            self.command = command
            self.path = path
        }
    }

    public struct GitHubCall: Sendable, Equatable {
        public let command: GitHubCommand
        public let path: String?

        public init(command: GitHubCommand, path: String?) {
            self.command = command
            self.path = path
        }
    }

    struct Calls: Sendable {
        var git: [GitCall] = []
        var gitHub: [GitHubCall] = []
    }
}
