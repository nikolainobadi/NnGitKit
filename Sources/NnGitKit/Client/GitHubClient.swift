import Foundation

public struct GitHubClient: Sendable {
    let runner: any GitCommandRunner

    public init(runner: any GitCommandRunner) {
        self.runner = runner
    }
}

// MARK: - Shared Helpers
extension GitHubClient {
    func readAPI(_ command: GitHubCommand, endpoint: String) throws -> String? {
        let result = try runner.runGitHub(command, at: nil)

        guard result.exitCode == 0 else {
            if result.output.contains(Self.notFoundMarker) {
                return nil
            }

            throw GitHubError.requestFailed(endpoint: endpoint, output: result.output)
        }

        return result.output
    }

    @discardableResult
    func runExpectingSuccess(_ command: GitHubCommand, at path: String?) throws -> String {
        let result = try runner.runGitHub(command, at: path)

        guard result.exitCode == 0 else {
            throw GitHubError.commandFailed(command: command, exitCode: result.exitCode, output: result.output)
        }

        return result.output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func nonEmpty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Private Methods
private extension GitHubClient {
    static let notFoundMarker = "(HTTP 404)"
}
