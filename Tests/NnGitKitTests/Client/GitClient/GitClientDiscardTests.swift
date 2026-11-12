import Testing
import NnGitKit
import NnGitTesting

struct GitClientDiscardTests {
    @Test
    func `Each discard runs its own git command`() throws {
        let sut = makeSUT(failing: nil)

        try sut.unstageAll(at: testRepoPath)
        try sut.unstage(paths: ["a.txt", "b.txt"], at: testRepoPath)
        try sut.resetHardToHead(at: testRepoPath)
        try sut.restoreWorktree(at: testRepoPath)
        try sut.restoreFromIndex(path: "a.txt", at: testRepoPath)
        try sut.restoreFromHead(path: "a.txt", at: testRepoPath)
        try sut.cleanUntracked(at: testRepoPath)
        try sut.cleanUntracked(path: "a.txt", at: testRepoPath)
    }

    @Test
    func `A refused restore throws git's message`() {
        let sut = makeSUT(failing: .restoreWorktree)

        let error = #expect(throws: GitError.self) {
            try sut.restoreWorktree(at: testRepoPath)
        }

        guard case .commandFailed(let command, let exitCode, let output) = error else {
            Issue.record("Expected a failed command")
            return
        }

        #expect(command == .restoreWorktree)
        #expect(exitCode == 1)
        #expect(output == "error: path is unmerged")
    }
}

// MARK: - Helpers
private extension GitClientDiscardTests {
    var testRepoPath: String {
        return "/Users/dev/nngit"
    }

    var commands: [GitCommand] {
        return [
            .resetIndex,
            .resetIndexPaths(paths: ["a.txt", "b.txt"]),
            .resetHardHead,
            .restoreWorktree,
            .restoreFromIndex(path: "a.txt"),
            .restoreFromHead(path: "a.txt"),
            .cleanUntracked,
            .cleanPath(path: "a.txt")
        ]
    }
}

// MARK: - SUT
private extension GitClientDiscardTests {
    func makeSUT(failing: GitCommand?) -> GitClient {
        let results = commands.map { command in
            let output = command == failing ? GitCommandOutput(exitCode: 1, output: "error: path is unmerged") : GitCommandOutput(exitCode: 0, output: "")

            return MockGitCommandRunner.GitResult(command: command, path: testRepoPath, output: output)
        }

        return .init(runner: MockGitCommandRunner(gitResults: results, gitHubResults: []))
    }
}
