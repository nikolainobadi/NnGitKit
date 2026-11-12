import Testing
import NnGitKit
import NnGitTesting

struct GitClientBranchesTests {
    @Test
    func `A tracked branch reports its upstream's name, remote, and merge ref`() throws {
        let sut = makeSUT(command: upstreamCommand, output: .init(exitCode: 0, output: "origin/main\0origin\0refs/heads/main\0[ahead 2]\n"))

        let upstream = try #require(try sut.upstream(of: "main", at: testRepoPath))

        #expect(upstream == .init(name: "origin/main", remote: "origin", mergeRef: "refs/heads/main", remoteBranchIsGone: false))
    }

    @Test
    func `An upstream whose remote branch was deleted is reported as gone`() throws {
        let sut = makeSUT(command: upstreamCommand, output: .init(exitCode: 0, output: "origin/main\0origin\0refs/heads/main\0[gone]\n"))

        let upstream = try #require(try sut.upstream(of: "main", at: testRepoPath))

        #expect(upstream.remoteBranchIsGone)
    }

    @Test
    func `A branch with no upstream configured has no upstream`() throws {
        let sut = makeSUT(command: upstreamCommand, output: .init(exitCode: 0, output: "\0\0\0\n"))

        #expect(try sut.upstream(of: "main", at: testRepoPath) == nil)
    }

    @Test
    func `A branch that doesn't exist has no upstream`() throws {
        let sut = makeSUT(command: upstreamCommand, output: .init(exitCode: 0, output: ""))

        #expect(try sut.upstream(of: "main", at: testRepoPath) == nil)
    }

    @Test
    func `A symbolic ref resolves to its short target`() throws {
        let sut = makeSUT(command: remoteHeadCommand, output: .init(exitCode: 0, output: "origin/main\n"))

        #expect(try sut.symbolicRef("refs/remotes/origin/HEAD", at: testRepoPath) == "origin/main")
    }

    @Test
    func `A missing symbolic ref resolves to nothing`() throws {
        let sut = makeSUT(command: remoteHeadCommand, output: .init(exitCode: 1, output: ""))

        #expect(try sut.symbolicRef("refs/remotes/origin/HEAD", at: testRepoPath) == nil)
    }

    @Test
    func `A failed branch creation surfaces git's output`() {
        let sut = makeSUT(command: .switchCreate(branch: "login-form"), output: .init(exitCode: 128, output: "fatal: a branch named 'login-form' already exists"))

        #expect(throws: GitError.self) {
            try sut.createAndSwitchToBranch("login-form", at: testRepoPath)
        }
    }

    @Test
    func `A branch is moved to the given target`() throws {
        let sut = makeSUT(command: .branchForce(branch: "main", target: "origin/main"), output: .init(exitCode: 0, output: ""))

        try sut.moveBranch("main", to: "origin/main", at: testRepoPath)
    }
}

// MARK: - Local Branch Details
extension GitClientBranchesTests {
    @Test
    func `A branch checked out in a worktree reports that worktree's path`() throws {
        let sut = makeSUT(command: .localBranchDetails, output: .init(exitCode: 0, output: "feature/login\0/Users/dev/nngit-login\0\0"))

        let branches = try sut.localBranches(at: testRepoPath)

        #expect(branches == [.init(name: "feature/login", worktreePath: "/Users/dev/nngit-login", upstreamName: nil, upstreamGone: false, ahead: 0, behind: 0)])
    }

    @Test
    func `A branch in sync with its upstream is neither ahead nor behind`() throws {
        let sut = makeSUT(command: .localBranchDetails, output: .init(exitCode: 0, output: "main\0\0origin/main\0"))

        let branch = try #require(try sut.localBranches(at: testRepoPath).first)

        #expect(branch == .init(name: "main", worktreePath: nil, upstreamName: "origin/main", upstreamGone: false, ahead: 0, behind: 0))
    }

    @Test
    func `A branch ahead of its upstream reports how far`() throws {
        let sut = makeSUT(command: .localBranchDetails, output: .init(exitCode: 0, output: "main\0\0origin/main\0ahead 3"))

        let branch = try #require(try sut.localBranches(at: testRepoPath).first)

        #expect(branch.ahead == 3)
        #expect(branch.behind == 0)
    }

    @Test
    func `A branch behind its upstream reports how far`() throws {
        let sut = makeSUT(command: .localBranchDetails, output: .init(exitCode: 0, output: "main\0\0origin/main\0behind 2"))

        let branch = try #require(try sut.localBranches(at: testRepoPath).first)

        #expect(branch.ahead == 0)
        #expect(branch.behind == 2)
    }

    @Test
    func `A branch that has diverged from its upstream reports both counts`() throws {
        let sut = makeSUT(command: .localBranchDetails, output: .init(exitCode: 0, output: "main\0\0origin/main\0ahead 1, behind 4"))

        let branch = try #require(try sut.localBranches(at: testRepoPath).first)

        #expect(branch.ahead == 1)
        #expect(branch.behind == 4)
    }

    @Test
    func `A branch whose remote branch was deleted reports its upstream as gone`() throws {
        let sut = makeSUT(command: .localBranchDetails, output: .init(exitCode: 0, output: "feature/login\0\0origin/feature/login\0gone"))

        let branch = try #require(try sut.localBranches(at: testRepoPath).first)

        #expect(branch.upstreamGone)
        #expect(branch.upstreamName == "origin/feature/login")
    }

    @Test
    func `Each output line becomes one branch`() throws {
        let output = "feature/login\0\0\0\nmain\0/Users/dev/nngit\0origin/main\0"
        let sut = makeSUT(command: .localBranchDetails, output: .init(exitCode: 0, output: output))

        #expect(try sut.localBranches(at: testRepoPath).map(\.name) == ["feature/login", "main"])
    }

    @Test
    func `A repository with no branches has no local branches`() throws {
        let sut = makeSUT(command: .localBranchDetails, output: .init(exitCode: 0, output: ""))

        #expect(try sut.localBranches(at: testRepoPath).isEmpty)
    }
}

// MARK: - Switching and Deleting
extension GitClientBranchesTests {
    @Test
    func `A switch to a branch held by another worktree surfaces git's output`() {
        let output = "fatal: 'feature/login' is already used by worktree at '/Users/dev/nngit-login'"
        let sut = makeSUT(command: .switchBranch(branch: "feature/login"), output: .init(exitCode: 128, output: output))

        #expect(throws: GitError.self) {
            try sut.switchToBranch("feature/login", at: testRepoPath)
        }
    }

    @Test
    func `A remote branch is switched to through a tracking branch`() throws {
        let sut = makeSUT(command: .switchTrack(remoteBranch: "origin/feature/login"), output: .init(exitCode: 0, output: ""))

        try sut.switchToNewTrackingBranch(for: "origin/feature/login", at: testRepoPath)
    }

    @Test
    func `A failed branch deletion surfaces git's output`() {
        let sut = makeSUT(command: .deleteBranchForce(branch: "feature/login"), output: .init(exitCode: 1, output: "error: branch 'feature/login' not found"))

        #expect(throws: GitError.self) {
            try sut.deleteBranch("feature/login", at: testRepoPath)
        }
    }

    @Test
    func `A branch's commit is read from its full ref`() throws {
        let sut = makeSUT(command: .revParseCommit(ref: "refs/heads/feature/login"), output: .init(exitCode: 0, output: "4db921a99a05597c38641b32d19f5bfaef931b6a\n"))

        #expect(try sut.commit(of: "feature/login", at: testRepoPath) == "4db921a99a05597c38641b32d19f5bfaef931b6a")
    }

    @Test
    func `A branch that doesn't exist has no commit`() throws {
        let sut = makeSUT(command: .revParseCommit(ref: "refs/heads/feature/login"), output: .init(exitCode: 1, output: ""))

        #expect(try sut.commit(of: "feature/login", at: testRepoPath) == nil)
    }
}

// MARK: - Helpers
private extension GitClientBranchesTests {
    var testRepoPath: String {
        return "/Users/dev/nngit"
    }

    var upstreamCommand: GitCommand {
        return .upstreamDetails(branch: "main")
    }

    var remoteHeadCommand: GitCommand {
        return .symbolicRefShort(ref: "refs/remotes/origin/HEAD")
    }
}

// MARK: - SUT
private extension GitClientBranchesTests {
    func makeSUT(command: GitCommand, output: GitCommandOutput) -> GitClient {
        let runner = MockGitCommandRunner(gitResults: [.init(command: command, path: testRepoPath, output: output)], gitHubResults: [])

        return .init(runner: runner)
    }
}
