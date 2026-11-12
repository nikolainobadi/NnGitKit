import Testing
import NnGitKit
import NnGitTesting

struct GitClientStatusTests {
    @Test
    func `A branch merged into main is an ancestor of main`() throws {
        let sut = makeSUT(command: isAncestorCommand, output: .init(exitCode: 0, output: ""))

        #expect(try sut.isAncestor("feature/login", of: "main", at: testRepoPath))
    }

    @Test
    func `A branch not merged into main is not an ancestor of main`() throws {
        let sut = makeSUT(command: isAncestorCommand, output: .init(exitCode: 1, output: ""))

        #expect(try sut.isAncestor("feature/login", of: "main", at: testRepoPath) == false)
    }

    @Test
    func `A repository root lookup inside a work tree finds the root`() throws {
        let sut = makeSUT(command: .revParseTopLevel, output: .init(exitCode: 0, output: "/Users/dev/nngit\n"))

        #expect(try sut.repositoryRootLookup(at: testRepoPath) == .found(path: "/Users/dev/nngit"))
    }

    @Test
    func `A repository root lookup outside a work tree keeps git's reason`() throws {
        let sut = makeSUT(command: .revParseTopLevel, output: .init(exitCode: 128, output: "fatal: not a git repository (or any of the parent directories): .git\n"))

        #expect(try sut.repositoryRootLookup(at: testRepoPath) == .notFound(output: "fatal: not a git repository (or any of the parent directories): .git"))
    }

    @Test
    func `The git directory is read as an absolute path`() throws {
        let sut = makeSUT(command: .revParseAbsoluteGitDir, output: .init(exitCode: 0, output: "/Users/dev/nngit/.git\n"))

        #expect(try sut.gitDirectory(at: testRepoPath) == "/Users/dev/nngit/.git")
    }

    @Test
    func `Commit summaries are returned one per commit`() throws {
        let sut = makeSUT(command: .logOneline(range: "origin/main..main"), output: .init(exitCode: 0, output: "d4e5f6 fix typo\nc3d4e5 add login form\n"))

        #expect(try sut.commitSummaries(in: "origin/main..main", at: testRepoPath) == ["d4e5f6 fix typo", "c3d4e5 add login form"])
    }

    @Test
    func `A set config value is returned`() throws {
        let sut = makeSUT(command: defaultBranchConfigCommand, output: .init(exitCode: 0, output: "develop\n"))

        #expect(try sut.configValue(for: "githappens.defaultbranch", at: testRepoPath) == "develop")
    }

    @Test
    func `An unset config value is nothing`() throws {
        let sut = makeSUT(command: defaultBranchConfigCommand, output: .init(exitCode: 1, output: ""))

        #expect(try sut.configValue(for: "githappens.defaultbranch", at: testRepoPath) == nil)
    }

    @Test
    func `Commits between two refs are counted`() throws {
        let sut = makeSUT(command: .revListCountRange(base: "HEAD", tip: "origin/main"), output: .init(exitCode: 0, output: "4\n"))

        #expect(try sut.commitCount(from: "HEAD", to: "origin/main", at: testRepoPath) == 4)
    }

    @Test
    func `Commits can't be counted against a ref that doesn't exist`() throws {
        let sut = makeSUT(command: .revListCountRange(base: "HEAD", tip: "origin/develop"), output: .init(exitCode: 128, output: "fatal: ambiguous argument 'HEAD..origin/develop'"))

        #expect(try sut.commitCount(from: "HEAD", to: "origin/develop", at: testRepoPath) == nil)
    }

    @Test
    func `Uncommitted paths include changed, renamed, and untracked files`() throws {
        let sut = makeSUT(command: .statusPorcelainPaths, output: .init(exitCode: 0, output: mixedStatusOutput))

        #expect(try sut.uncommittedPaths(at: testRepoPath) == ["Sources/App.swift", "Sources/New.swift", "Sources/Old.swift", "notes.txt"])
    }

    @Test
    func `Untracked paths include only files git doesn't track`() throws {
        let sut = makeSUT(command: .statusPorcelainPaths, output: .init(exitCode: 0, output: mixedStatusOutput))

        #expect(try sut.untrackedPaths(at: testRepoPath) == ["notes.txt"])
    }

    @Test
    func `A rename counts once and untracked files count as added`() throws {
        let sut = makeSUT(command: .statusPorcelainPaths, output: .init(exitCode: 0, output: mixedStatusOutput))

        #expect(try sut.uncommittedFileCounts(at: testRepoPath) == .init(added: 1, modified: 2, deleted: 0))
    }

    @Test
    func `Staged and unstaged changes are counted by what happened to the file`() throws {
        let output = [
            "1 A. N... 000000 100644 100644 000000 a1b2c3 Sources/Staged.swift",
            "1 AM N... 000000 100644 100644 000000 a1b2c3 Sources/StagedThenEdited.swift",
            "1 M. N... 100644 100644 100644 a1b2c3 d4e5f6 Sources/Edited.swift",
            "1 D. N... 100644 000000 000000 a1b2c3 000000 Sources/StagedRemoval.swift",
            "1 .D N... 100644 100644 000000 a1b2c3 a1b2c3 Sources/Removed.swift",
            "u UU N... 100644 100644 100644 100644 a1b2c3 d4e5f6 a7b8c9 Sources/Conflict.swift"
        ].joined(separator: "\0")
        let sut = makeSUT(command: .statusPorcelainPaths, output: .init(exitCode: 0, output: output))

        #expect(try sut.uncommittedFileCounts(at: testRepoPath) == .init(added: 2, modified: 2, deleted: 2))
    }

    @Test
    func `A clean work tree counts nothing`() throws {
        let sut = makeSUT(command: .statusPorcelainPaths, output: .init(exitCode: 0, output: ""))

        #expect(try sut.uncommittedFileCounts(at: testRepoPath) == .clean)
    }

    @Test
    func `A clean work tree has no untracked paths`() throws {
        let sut = makeSUT(command: .statusPorcelainPaths, output: .init(exitCode: 0, output: ""))

        #expect(try sut.untrackedPaths(at: testRepoPath).isEmpty)
    }

    @Test(arguments: [
        (line: "1 M. N... 100644 100644 100644 a1b2c3 d4e5f6 f.txt", staged: true, unstaged: false, existsInHead: true, change: UncommittedFile.Change.modified),
        (line: "1 .M N... 100644 100644 100644 a1b2c3 a1b2c3 f.txt", staged: false, unstaged: true, existsInHead: true, change: .modified),
        (line: "1 AM N... 000000 100644 100644 000000 a1b2c3 f.txt", staged: true, unstaged: true, existsInHead: false, change: .added),
        (line: "1 A. N... 000000 100644 100644 000000 a1b2c3 f.txt", staged: true, unstaged: false, existsInHead: false, change: .added),
        (line: "1 D. N... 100644 000000 000000 a1b2c3 000000 f.txt", staged: true, unstaged: false, existsInHead: true, change: .deleted),
        (line: "1 .D N... 100644 100644 000000 a1b2c3 a1b2c3 f.txt", staged: false, unstaged: true, existsInHead: true, change: .deleted),
        (line: "1 .T N... 100644 100644 120000 a1b2c3 a1b2c3 f.txt", staged: false, unstaged: true, existsInHead: true, change: .modified)
    ])
    func `An ordinary entry reports which layers changed`(example: (line: String, staged: Bool, unstaged: Bool, existsInHead: Bool, change: UncommittedFile.Change)) throws {
        let sut = makeSUT(command: .statusPorcelainCollapsed, output: .init(exitCode: 0, output: example.line))

        #expect(try sut.uncommittedFiles(at: testRepoPath) == [
            .init(path: "f.txt", originalPath: nil, hasStagedChanges: example.staged, hasUnstagedChanges: example.unstaged, untracked: false, conflicted: false, existsInHead: example.existsInHead, change: example.change)
        ])
    }

    @Test
    func `A renamed entry keeps both of its paths`() throws {
        let output = ["2 RM N... 100644 100644 100644 d4e5f6 d4e5f6 R100 Sources/My New.swift", "Sources/Old.swift"].joined(separator: "\0")
        let sut = makeSUT(command: .statusPorcelainCollapsed, output: .init(exitCode: 0, output: output))

        #expect(try sut.uncommittedFiles(at: testRepoPath) == [
            .init(path: "Sources/My New.swift", originalPath: "Sources/Old.swift", hasStagedChanges: true, hasUnstagedChanges: true, untracked: false, conflicted: false, existsInHead: true, change: .modified)
        ])
    }

    @Test(arguments: [
        (line: "u UU N... 100644 100644 100644 100644 a1b2c3 d4e5f6 a7b8c9 f.txt", existsInHead: true),
        (line: "u DU N... 100644 000000 100644 100644 a1b2c3 000000 a7b8c9 f.txt", existsInHead: false)
    ])
    func `A conflicted entry changes both layers and reads our side for HEAD`(example: (line: String, existsInHead: Bool)) throws {
        let sut = makeSUT(command: .statusPorcelainCollapsed, output: .init(exitCode: 0, output: example.line))

        #expect(try sut.uncommittedFiles(at: testRepoPath) == [
            .init(path: "f.txt", originalPath: nil, hasStagedChanges: true, hasUnstagedChanges: true, untracked: false, conflicted: true, existsInHead: example.existsInHead, change: .modified)
        ])
    }

    @Test
    func `An untracked folder is one unstaged row`() throws {
        let sut = makeSUT(command: .statusPorcelainCollapsed, output: .init(exitCode: 0, output: "? big/\0? notes file.txt\0"))

        #expect(try sut.uncommittedFiles(at: testRepoPath) == [
            .init(path: "big/", originalPath: nil, hasStagedChanges: false, hasUnstagedChanges: true, untracked: true, conflicted: false, existsInHead: false, change: .added),
            .init(path: "notes file.txt", originalPath: nil, hasStagedChanges: false, hasUnstagedChanges: true, untracked: true, conflicted: false, existsInHead: false, change: .added)
        ])
    }

    @Test
    func `A clean work tree has no uncommitted files`() throws {
        let sut = makeSUT(command: .statusPorcelainCollapsed, output: .init(exitCode: 0, output: ""))

        #expect(try sut.uncommittedFiles(at: testRepoPath).isEmpty)
    }

    @Test
    func `Paths a reset would restore are split on nulls`() throws {
        let sut = makeSUT(command: .diffPathsMissingFromHead(target: "abc123"), output: .init(exitCode: 0, output: "d/x\0a file\0"))

        #expect(try sut.pathsRestoredByReset(to: "abc123", at: testRepoPath) == ["d/x", "a file"])
    }

    @Test
    func `No restored paths come back empty`() throws {
        let sut = makeSUT(command: .diffPathsMissingFromHead(target: "abc123"), output: .init(exitCode: 0, output: ""))

        #expect(try sut.pathsRestoredByReset(to: "abc123", at: testRepoPath).isEmpty)
    }

    @Test
    func `A failed restored paths read throws`() {
        let sut = makeSUT(command: .diffPathsMissingFromHead(target: "abc123"), output: .init(exitCode: 128, output: "fatal: bad object"))

        #expect(throws: GitError.self) {
            try sut.pathsRestoredByReset(to: "abc123", at: testRepoPath)
        }
    }

    @Test
    func `Unversioned paths are looked up with each parent folder once`() throws {
        let sut = makeSUT(command: .lsFilesOthers(paths: ["d", "d/e", "d/e/x", "d/e/y", "f"]), output: .init(exitCode: 0, output: "d/e/x\0f\0"))

        #expect(try sut.unversionedPaths(overlapping: ["d/e/x", "d/e/y", "f"], ignoringCase: false, at: testRepoPath) == ["d/e/x", "f"])
    }

    @Test
    func `Ignoring case lists every unversioned file, because pathspecs only ignore ASCII case`() throws {
        let sut = makeSUT(command: .lsFilesOthers(paths: []), output: .init(exitCode: 0, output: "foo.txt\0other\0"))

        #expect(try sut.unversionedPaths(overlapping: ["Foo.txt"], ignoringCase: true, at: testRepoPath) == ["foo.txt", "other"])
    }

    @Test
    func `No paths to look up runs no git, even when ignoring case`() throws {
        let sut = GitClient(runner: MockGitCommandRunner(gitResults: [], gitHubResults: []))

        #expect(try sut.unversionedPaths(overlapping: [], ignoringCase: true, at: testRepoPath).isEmpty)
    }

    @Test
    func `No paths to look up runs no git`() throws {
        let sut = GitClient(runner: MockGitCommandRunner(gitResults: [], gitHubResults: []))

        #expect(try sut.unversionedPaths(overlapping: [], ignoringCase: false, at: testRepoPath).isEmpty)
    }

    @Test
    func `A failed unversioned paths read throws`() {
        let sut = makeSUT(command: .lsFilesOthers(paths: ["f"]), output: .init(exitCode: 128, output: "fatal: not a git repository"))

        #expect(throws: GitError.self) {
            try sut.unversionedPaths(overlapping: ["f"], ignoringCase: false, at: testRepoPath)
        }
    }

    @Test
    func `An unreadable config throws`() {
        let sut = makeSUT(command: defaultBranchConfigCommand, output: .init(exitCode: 3, output: "error: invalid config file"))

        #expect(throws: GitError.self) {
            try sut.configValue(for: "githappens.defaultbranch", at: testRepoPath)
        }
    }

    @Test
    func `A revision that resolves returns its commit`() throws {
        let sut = makeSUT(command: .revParseCommit(ref: "v1.2.0"), output: .init(exitCode: 0, output: "4db921a9f\n"))

        #expect(try sut.commit(ofRevision: "v1.2.0", at: testRepoPath) == "4db921a9f")
    }

    @Test
    func `A revision that resolves to nothing has no commit`() throws {
        let sut = makeSUT(command: .revParseCommit(ref: "nope"), output: .init(exitCode: 1, output: ""))

        #expect(try sut.commit(ofRevision: "nope", at: testRepoPath) == nil)
    }
}

// MARK: - Helpers
private extension GitClientStatusTests {
    var testRepoPath: String {
        return "/Users/dev/nngit"
    }

    var isAncestorCommand: GitCommand {
        return .isAncestor(ancestor: "feature/login", descendant: "main")
    }

    var defaultBranchConfigCommand: GitCommand {
        return .configGet(key: "githappens.defaultbranch")
    }

    var mixedStatusOutput: String {
        return [
            "1 .M N... 100644 100644 100644 a1b2c3 a1b2c3 Sources/App.swift",
            "2 R. N... 100644 100644 100644 d4e5f6 d4e5f6 R100 Sources/New.swift",
            "Sources/Old.swift",
            "? notes.txt"
        ].joined(separator: "\0")
    }
}

// MARK: - SUT
private extension GitClientStatusTests {
    func makeSUT(command: GitCommand, output: GitCommandOutput) -> GitClient {
        let runner = MockGitCommandRunner(gitResults: [.init(command: command, path: testRepoPath, output: output)], gitHubResults: [])

        return .init(runner: runner)
    }
}
