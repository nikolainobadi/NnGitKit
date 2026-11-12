public protocol GitCommandRunner: Sendable {
    func runGit(_ command: GitCommand, at path: String) throws -> GitCommandOutput
    func runGitHub(_ command: GitHubCommand, at path: String?) throws -> GitCommandOutput
}

public struct GitCommandOutput: Sendable, Equatable {
    public let exitCode: Int32
    public let output: String

    public init(exitCode: Int32, output: String) {
        self.exitCode = exitCode
        self.output = output
    }
}
