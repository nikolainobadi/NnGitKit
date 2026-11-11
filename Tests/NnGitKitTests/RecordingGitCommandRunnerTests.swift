import Testing
import NnGitKit
import NnGitTesting

struct RecordingGitCommandRunnerTests {
    @Test
    func `Git calls are recorded in order with their paths`() throws {
        let sut = makeSUT(gitResults: [succeeded(.addAll, at: "/a"), succeeded(.remote, at: "/b")], gitHubResults: [])

        _ = try sut.runGit(.addAll, at: "/a")
        _ = try sut.runGit(.remote, at: "/b")

        #expect(sut.gitCalls == [.init(command: .addAll, path: "/a"), .init(command: .remote, path: "/b")])
        #expect(sut.gitCommands == [.addAll, .remote])
    }

    @Test
    func `GitHub calls are recorded in order with their paths`() throws {
        let sut = makeSUT(gitResults: [], gitHubResults: [.init(command: .authStatus, path: nil, output: .init(exitCode: 0, output: ""))])

        _ = try sut.runGitHub(.authStatus, at: nil)

        #expect(sut.gitHubCalls == [.init(command: .authStatus, path: nil)])
        #expect(sut.gitHubCommands == [.authStatus])
    }

    @Test
    func `A scripted failure is returned as its exit code and output`() throws {
        let failure = GitCommandOutput(exitCode: 128, output: "fatal: nope")
        let sut = makeSUT(gitResults: [.init(command: .addAll, path: "/a", output: failure)], gitHubResults: [])

        #expect(try sut.runGit(.addAll, at: "/a") == failure)
    }

    @Test
    func `An unscripted command throws and is still recorded`() {
        let sut = makeSUT(gitResults: [], gitHubResults: [])

        #expect(throws: MockGitCommandRunner.UnexpectedCommand.git(command: .addAll, path: "/a")) {
            try sut.runGit(.addAll, at: "/a")
        }
        #expect(sut.gitCommands == [.addAll])
    }
}

// MARK: - Helpers
private extension RecordingGitCommandRunnerTests {
    func succeeded(_ command: GitCommand, at path: String) -> MockGitCommandRunner.GitResult {
        return .init(command: command, path: path, output: .init(exitCode: 0, output: ""))
    }
}

// MARK: - SUT
private extension RecordingGitCommandRunnerTests {
    func makeSUT(gitResults: [MockGitCommandRunner.GitResult], gitHubResults: [MockGitCommandRunner.GitHubResult]) -> RecordingGitCommandRunner {
        return .init(gitResults: gitResults, gitHubResults: gitHubResults)
    }
}
