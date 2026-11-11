import Foundation

public struct GitClient: Sendable {
    let runner: any GitCommandRunner

    public init(runner: any GitCommandRunner) {
        self.runner = runner
    }
}

// MARK: - Shared Helpers
extension GitClient {
    @discardableResult
    func runExpectingSuccess(_ command: GitCommand, at path: String) throws -> String {
        let result = try runner.runGit(command, at: path)

        guard result.exitCode == 0 else {
            throw GitError.commandFailed(command: command, exitCode: result.exitCode, output: result.output)
        }

        return trimmed(result.output)
    }

    func trimmed(_ output: String) -> String {
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func lines(of output: String) -> [String] {
        return output.split(whereSeparator: \.isNewline).map(String.init)
    }
}
