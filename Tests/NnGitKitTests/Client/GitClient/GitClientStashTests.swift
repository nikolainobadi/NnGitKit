import Testing
import NnGitKit
import NnGitTesting

struct GitClientStashTests {
    @Test
    func `No stashes reads as an empty list`() throws {
        let sut = makeSUT(output: .init(exitCode: 0, output: ""))

        #expect(try sut.stashEntries(at: testRepoPath) == [])
    }

    @Test
    func `Each stash line is one entry, in git's order`() throws {
        let output = "stash@{0}: WIP on main: 1a2b3c4 Add login\nstash@{1}: On feature/login: spike\n"
        let sut = makeSUT(output: .init(exitCode: 0, output: output))

        #expect(try sut.stashEntries(at: testRepoPath) == [
            "stash@{0}: WIP on main: 1a2b3c4 Add login",
            "stash@{1}: On feature/login: spike"
        ])
    }

    @Test
    func `A failed stash listing throws git's message`() {
        let sut = makeSUT(output: .init(exitCode: 128, output: "fatal: not a git repository"))

        let error = #expect(throws: GitError.self) {
            try sut.stashEntries(at: testRepoPath)
        }

        guard case .commandFailed(let command, let exitCode, let output) = error else {
            Issue.record("Expected a failed command")
            return
        }

        #expect(command == .stashList)
        #expect(exitCode == 128)
        #expect(output == "fatal: not a git repository")
    }
}

// MARK: - Helpers
private extension GitClientStashTests {
    var testRepoPath: String {
        return "/Users/dev/nngit"
    }
}

// MARK: - SUT
private extension GitClientStashTests {
    func makeSUT(output: GitCommandOutput) -> GitClient {
        let runner = MockGitCommandRunner(gitResults: [.init(command: .stashList, path: testRepoPath, output: output)], gitHubResults: [])

        return .init(runner: runner)
    }
}
