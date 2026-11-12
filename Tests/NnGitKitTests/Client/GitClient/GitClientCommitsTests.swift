import Testing
import NnGitKit
import NnGitTesting

struct GitClientCommitsTests {
    @Test
    func `Recent commits keep punctuation in subjects`() throws {
        let sut = makeSUT(command: .logFirstParent(limit: 8), output: .init(exitCode: 0, output: record("fix(a, b): keep (this)", parents: "p1") + "\n"))

        let commits = try sut.recentCommits(limit: 8, at: testRepoPath)

        #expect(commits == [
            .init(sha: "abc123def", shortSha: "abc123", subject: "fix(a, b): keep (this)", authorName: "Jane Doe", authorEmail: "jane@example.com", relativeDate: "2 days ago", parentCount: 1)
        ])
    }

    @Test(arguments: [
        (parents: "", expected: 0),
        (parents: "p1", expected: 1),
        (parents: "p1 p2", expected: 2)
    ])
    func `The parent count comes from the parent list`(example: (parents: String, expected: Int)) throws {
        let sut = makeSUT(command: .logFirstParent(limit: 8), output: .init(exitCode: 0, output: record("one", parents: example.parents)))

        #expect(try sut.recentCommits(limit: 8, at: testRepoPath).map(\.parentCount) == [example.expected])
    }

    @Test
    func `Several commits stay in git's order`() throws {
        let output = record("newer", parents: "p1") + "\n" + record("older", parents: "") + "\n"
        let sut = makeSUT(command: .logFirstParent(limit: 8), output: .init(exitCode: 0, output: output))

        #expect(try sut.recentCommits(limit: 8, at: testRepoPath).map(\.subject) == ["newer", "older"])
    }

    @Test
    func `A record that can't be read throws instead of being dropped`() {
        let output = record("newer", parents: "p1") + "\nnot a record\u{1e}\n" + record("older", parents: "")
        let sut = makeSUT(command: .logFirstParent(limit: 8), output: .init(exitCode: 0, output: output))

        let error = #expect(throws: GitError.self) {
            try sut.recentCommits(limit: 8, at: testRepoPath)
        }

        guard case .unreadableOutput(let command, let unreadable) = error else {
            Issue.record("Expected unreadable output")
            return
        }

        #expect(command == .logFirstParent(limit: 8))
        #expect(unreadable == "not a record")
    }

    @Test
    func `A reset git refuses throws git's message`() {
        let command = GitCommand.reset(mode: .soft, target: "abc123")
        let sut = makeSUT(command: command, output: .init(exitCode: 128, output: "fatal: Cannot do a soft reset in the middle of a merge."))

        let error = #expect(throws: GitError.self) {
            try sut.reset(to: "abc123", mode: .soft, at: testRepoPath)
        }

        guard case .commandFailed(let failedCommand, let exitCode, let output) = error else {
            Issue.record("Expected a failed command")
            return
        }

        #expect(failedCommand == command)
        #expect(exitCode == 128)
        #expect(output == "fatal: Cannot do a soft reset in the middle of a merge.")
    }
}

// MARK: - Helpers
private extension GitClientCommitsTests {
    var testRepoPath: String {
        return "/Users/dev/nngit"
    }

    func record(_ subject: String, parents: String) -> String {
        return ["abc123def", "abc123", subject, "Jane Doe", "jane@example.com", "2 days ago", parents].joined(separator: "\0") + "\u{1e}"
    }
}

// MARK: - SUT
private extension GitClientCommitsTests {
    func makeSUT(command: GitCommand, output: GitCommandOutput) -> GitClient {
        let runner = MockGitCommandRunner(gitResults: [.init(command: command, path: testRepoPath, output: output)], gitHubResults: [])

        return .init(runner: runner)
    }
}
