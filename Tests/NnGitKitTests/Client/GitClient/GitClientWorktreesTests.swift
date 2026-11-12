import Testing
import NnGitKit
import NnGitTesting

struct GitClientWorktreesTests {
    @Test
    func `The main checkout is listed first and marked primary`() throws {
        let output = "worktree /Users/dev/nngit\0HEAD 4db921a\0branch refs/heads/main\0\0worktree /Users/dev/nngit-login\0HEAD 4db921a\0branch refs/heads/feature/login\0\0"
        let sut = makeSUT(command: .worktreeList, output: .init(exitCode: 0, output: output))

        let worktrees = try sut.worktrees(at: testRepoPath)

        #expect(worktrees == [
            .init(path: "/Users/dev/nngit", branch: "main", primary: true, detached: false, locked: false, lockReason: nil, prunable: false),
            .init(path: "/Users/dev/nngit-login", branch: "feature/login", primary: false, detached: false, locked: false, lockReason: nil, prunable: false)
        ])
    }

    @Test
    func `A detached worktree has no branch`() throws {
        let output = "worktree /Users/dev/nngit\0HEAD 4db921a\0branch refs/heads/main\0\0worktree /Users/dev/nngit-review\0HEAD 4db921a\0detached\0\0"
        let sut = makeSUT(command: .worktreeList, output: .init(exitCode: 0, output: output))

        let worktree = try #require(try sut.worktrees(at: testRepoPath).last)

        #expect(worktree.branch == nil)
        #expect(worktree.detached)
    }

    @Test
    func `A locked worktree keeps the reason it was locked`() throws {
        let output = "worktree /Users/dev/nngit-login\0HEAD 4db921a\0branch refs/heads/feature/login\0locked on usb drive\0\0"
        let sut = makeSUT(command: .worktreeList, output: .init(exitCode: 0, output: output))

        let worktree = try #require(try sut.worktrees(at: testRepoPath).first)

        #expect(worktree.locked)
        #expect(worktree.lockReason == "on usb drive")
    }

    @Test
    func `A worktree locked without a reason has no lock reason`() throws {
        let output = "worktree /Users/dev/nngit-login\0HEAD 4db921a\0branch refs/heads/feature/login\0locked\0\0"
        let sut = makeSUT(command: .worktreeList, output: .init(exitCode: 0, output: output))

        let worktree = try #require(try sut.worktrees(at: testRepoPath).first)

        #expect(worktree.locked)
        #expect(worktree.lockReason == nil)
    }

    @Test
    func `A worktree whose directory is gone is prunable`() throws {
        let output = "worktree /Users/dev/nngit-old\0HEAD 4db921a\0branch refs/heads/old\0prunable gitdir file points to non-existent location\0\0"
        let sut = makeSUT(command: .worktreeList, output: .init(exitCode: 0, output: output))

        let worktree = try #require(try sut.worktrees(at: testRepoPath).first)

        #expect(worktree.prunable)
        #expect(!worktree.locked)
    }

    @Test
    func `Output without a trailing separator still yields its last worktree`() throws {
        let output = "worktree /Users/dev/nngit\0HEAD 4db921a\0branch refs/heads/main"
        let sut = makeSUT(command: .worktreeList, output: .init(exitCode: 0, output: output))

        #expect(try sut.worktrees(at: testRepoPath).map(\.path) == ["/Users/dev/nngit"])
    }

    @Test
    func `A failed worktree listing surfaces git's output`() {
        let sut = makeSUT(command: .worktreeList, output: .init(exitCode: 128, output: "fatal: not a git repository"))

        #expect(throws: GitError.self) {
            try sut.worktrees(at: testRepoPath)
        }
    }

    @Test
    func `A worktree is removed with the given force`() throws {
        let sut = makeSUT(command: .worktreeRemove(path: "/Users/dev/nngit-login", force: .discardChanges), output: .init(exitCode: 0, output: ""))

        try sut.removeWorktree(at: "/Users/dev/nngit-login", force: .discardChanges, in: testRepoPath)
    }

    @Test
    func `A refused worktree removal surfaces git's output`() {
        let output = "fatal: '/Users/dev/nngit-login' contains modified or untracked files, use --force to delete it"
        let sut = makeSUT(command: .worktreeRemove(path: "/Users/dev/nngit-login", force: .none), output: .init(exitCode: 128, output: output))

        #expect(throws: GitError.self) {
            try sut.removeWorktree(at: "/Users/dev/nngit-login", force: .none, in: testRepoPath)
        }
    }

    @Test
    func `A worktree is added on a new branch from its base`() throws {
        let sut = makeSUT(command: .worktreeAddNewBranch(path: "/Users/dev/nngit/.worktrees/login", branch: "login", base: "origin/main"), output: .init(exitCode: 0, output: ""))

        try sut.addWorktree(at: "/Users/dev/nngit/.worktrees/login", newBranch: "login", from: "origin/main", in: testRepoPath)
    }

    @Test
    func `A worktree is added for an existing branch`() throws {
        let sut = makeSUT(command: .worktreeAdd(path: "/Users/dev/nngit/.worktrees/login", branch: "login"), output: .init(exitCode: 0, output: ""))

        try sut.addWorktree(at: "/Users/dev/nngit/.worktrees/login", branch: "login", in: testRepoPath)
    }

    @Test
    func `A worktree is added on a branch tracking a remote branch`() throws {
        let sut = makeSUT(command: .worktreeAddTracking(path: "/Users/dev/nngit/.worktrees/login", branch: "login", remoteBranch: "origin/login"), output: .init(exitCode: 0, output: ""))

        try sut.addWorktree(at: "/Users/dev/nngit/.worktrees/login", trackingBranch: "login", remoteBranch: "origin/login", in: testRepoPath)
    }

    @Test
    func `A refused worktree add surfaces git's output`() {
        let output = "fatal: 'login' is already checked out at '/Users/dev/nngit'"
        let sut = makeSUT(command: .worktreeAdd(path: "/Users/dev/nngit/.worktrees/login", branch: "login"), output: .init(exitCode: 128, output: output))

        #expect(throws: GitError.self) {
            try sut.addWorktree(at: "/Users/dev/nngit/.worktrees/login", branch: "login", in: testRepoPath)
        }
    }

    @Test
    func `Stale worktree records are pruned`() throws {
        let sut = makeSUT(command: .worktreePrune, output: .init(exitCode: 0, output: ""))

        try sut.pruneWorktrees(at: testRepoPath)
    }
}

// MARK: - Helpers
private extension GitClientWorktreesTests {
    var testRepoPath: String {
        return "/Users/dev/nngit"
    }
}

// MARK: - SUT
private extension GitClientWorktreesTests {
    func makeSUT(command: GitCommand, output: GitCommandOutput) -> GitClient {
        let runner = MockGitCommandRunner(gitResults: [.init(command: command, path: testRepoPath, output: output)], gitHubResults: [])

        return .init(runner: runner)
    }
}
