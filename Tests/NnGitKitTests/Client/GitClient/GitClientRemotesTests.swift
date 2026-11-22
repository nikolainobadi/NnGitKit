import Testing
import NnGitKit
import NnGitTesting

struct GitClientRemotesTests {
    @Test
    func `A remote's address is returned without surrounding whitespace`() throws {
        let sut = makeSUT(command: .remoteGetURL(name: "fork"), output: .init(exitCode: 0, output: "git@github.com:owner/repo.git\n"))

        #expect(try sut.remoteURL(of: "fork", at: testRepoPath) == "git@github.com:owner/repo.git")
    }

    @Test
    func `A remote git can't find has no address`() throws {
        let sut = makeSUT(command: .remoteGetURL(name: "fork"), output: .init(exitCode: 2, output: "error: No such remote 'fork'"))

        #expect(try sut.remoteURL(of: "fork", at: testRepoPath) == nil)
    }

    @Test
    func `A remote with an empty address has no address`() throws {
        let sut = makeSUT(command: .remoteGetURL(name: "fork"), output: .init(exitCode: 0, output: "\n"))

        #expect(try sut.remoteURL(of: "fork", at: testRepoPath) == nil)
    }

    @Test
    func `Commits ahead of the upstream are counted`() throws {
        let sut = makeSUT(command: .revListCountAheadOfUpstream(branch: "HEAD"), output: .init(exitCode: 0, output: "2\n"))

        let count = try #require(try sut.commitsAheadOfUpstream(of: "HEAD", at: testRepoPath))

        #expect(count == 2)
    }

    @Test
    func `A branch with no upstream has no ahead count`() throws {
        let sut = makeSUT(command: .revListCountAheadOfUpstream(branch: "main"), output: noUpstream)

        #expect(try sut.commitsAheadOfUpstream(of: "main", at: testRepoPath) == nil)
    }

    @Test
    func `Commits behind the upstream are counted for a branch that isn't checked out`() throws {
        let sut = makeSUT(command: .revListCountBehindUpstream(branch: "feature/login"), output: .init(exitCode: 0, output: "3\n"))

        let count = try #require(try sut.commitsBehindUpstream(of: "feature/login", at: testRepoPath))

        #expect(count == 3)
    }

    @Test
    func `A branch with no upstream has no behind count`() throws {
        let sut = makeSUT(command: .revListCountBehindUpstream(branch: "main"), output: noUpstream)

        #expect(try sut.commitsBehindUpstream(of: "main", at: testRepoPath) == nil)
    }

    @Test
    func `Each remote's HEAD branch is keyed by remote, skipping remotes without one`() throws {
        let runner = MockGitCommandRunner(
            gitResults: [
                .init(command: .symbolicRefShort(ref: "refs/remotes/origin/HEAD"), path: testRepoPath, output: .init(exitCode: 0, output: "origin/main\n")),
                .init(command: .symbolicRefShort(ref: "refs/remotes/fork/HEAD"), path: testRepoPath, output: .init(exitCode: 128, output: "fatal: ref refs/remotes/fork/HEAD is not a symbolic ref"))
            ],
            gitHubResults: []
        )
        let sut = GitClient(runner: runner)

        #expect(try sut.remoteHeadBranches(for: ["origin", "fork"], at: testRepoPath) == ["origin": "origin/main"])
    }

    @Test
    func `A successful fetch reports that it fetched`() throws {
        let sut = makeSUT(command: .fetchAllPruned, output: .init(exitCode: 0, output: ""))

        #expect(try sut.fetchAllPruned(at: testRepoPath) == .fetched)
    }

    @Test
    func `A failed fetch reports git's output instead of throwing`() throws {
        let sut = makeSUT(command: .fetchAllPruned, output: .init(exitCode: 1, output: "fatal: unable to access 'https://github.com/x/y.git/'\n"))

        #expect(try sut.fetchAllPruned(at: testRepoPath) == .failed(output: "fatal: unable to access 'https://github.com/x/y.git/'"))
    }

    @Test
    func `A fast-forward that isn't possible throws`() {
        let sut = makeSUT(command: .mergeFastForward(ref: "@{upstream}"), output: .init(exitCode: 128, output: "fatal: Not possible to fast-forward, aborting."))

        #expect(throws: GitError.self) {
            try sut.fastForward(to: "@{upstream}", at: testRepoPath)
        }
    }

    @Test
    func `A first push that succeeds doesn't throw`() throws {
        let sut = makeSUT(command: .pushSettingUpstream(remote: "origin", branch: "feature/login"), output: .init(exitCode: 0, output: ""))

        try sut.pushBranchSettingUpstream("feature/login", to: "origin", at: testRepoPath)
    }

    @Test
    func `A rejected first push throws`() {
        let command = GitCommand.pushSettingUpstream(remote: "origin", branch: "feature/login")
        let sut = makeSUT(command: command, output: .init(exitCode: 128, output: "fatal: Authentication failed for 'https://github.com/x/y.git/'"))

        #expect(throws: GitError.self) {
            try sut.pushBranchSettingUpstream("feature/login", to: "origin", at: testRepoPath)
        }
    }

    @Test
    func `A rejected push throws`() {
        let command = GitCommand.pushRefspec(remote: "origin", source: "main", destination: "refs/heads/main")
        let sut = makeSUT(command: command, output: .init(exitCode: 1, output: "! [remote rejected] main -> main (protected branch hook declined)"))

        #expect(throws: GitError.self) {
            try sut.push("main", to: "refs/heads/main", on: "origin", at: testRepoPath)
        }
    }

    @Test
    func `A clone runs in the destination's parent folder`() throws {
        let url = "git@github.com:dev/nngit.git"
        let destination = "/Users/dev/Projects/nngit"
        let sut = makeSUT(command: .clone(url: url, destination: destination), output: .init(exitCode: 0, output: ""), at: "/Users/dev/Projects")

        try sut.clone(url: url, to: destination)
    }

    @Test
    func `A failed clone throws git's message`() {
        let url = "https://github.com/dev/missing.git"
        let destination = "/Users/dev/Projects/missing"
        let command = GitCommand.clone(url: url, destination: destination)
        let output = "fatal: repository 'https://github.com/dev/missing.git/' not found"
        let sut = makeSUT(command: command, output: .init(exitCode: 128, output: output), at: "/Users/dev/Projects")

        let error = #expect(throws: GitError.self) {
            try sut.clone(url: url, to: destination)
        }

        guard case .commandFailed(let failedCommand, let exitCode, let failedOutput) = error else {
            Issue.record("Expected a failed command")
            return
        }

        #expect(failedCommand == command)
        #expect(exitCode == 128)
        #expect(failedOutput == output)
    }
}

// MARK: - Helpers
private extension GitClientRemotesTests {
    var testRepoPath: String {
        return "/Users/Home/HomebrewTaps/homebrew-nn"
    }

    var noUpstream: GitCommandOutput {
        return .init(exitCode: 128, output: "fatal: no upstream configured for branch 'main'")
    }
}

// MARK: - SUT
private extension GitClientRemotesTests {
    func makeSUT(command: GitCommand, output: GitCommandOutput) -> GitClient {
        return makeSUT(command: command, output: output, at: testRepoPath)
    }

    func makeSUT(command: GitCommand, output: GitCommandOutput, at path: String) -> GitClient {
        let runner = MockGitCommandRunner(gitResults: [.init(command: command, path: path, output: output)], gitHubResults: [])

        return .init(runner: runner)
    }
}
