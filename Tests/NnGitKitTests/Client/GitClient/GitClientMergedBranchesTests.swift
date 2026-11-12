import Testing
import NnGitKit
import NnGitTesting

struct GitClientMergedBranchesTests {
    @Test
    func `Branches merged into the ref are listed`() throws {
        let sut = makeSUT(gitResults: [result(.mergedBranches(ref: "origin/main"), exitCode: 0, output: "feature/login\nmain\n")])

        #expect(try sut.branchNames(mergedInto: "origin/main", at: testRepoPath) == ["feature/login", "main"])
    }

    @Test
    func `No merged branches is an empty list rather than nothing`() throws {
        let sut = makeSUT(gitResults: [result(.mergedBranches(ref: "origin/main"), exitCode: 0, output: "")])

        #expect(try sut.branchNames(mergedInto: "origin/main", at: testRepoPath) == [])
    }

    @Test
    func `A ref that doesn't resolve has no merged branches to report`() throws {
        let sut = makeSUT(gitResults: [result(.mergedBranches(ref: "origin/main"), exitCode: 128, output: "fatal: malformed object name origin/main")])

        #expect(try sut.branchNames(mergedInto: "origin/main", at: testRepoPath) == nil)
    }

    @Test
    func `A squash-merged branch counts as merged when merging it changes nothing`() throws {
        let sut = makeSUT(gitResults: [
            result(.revParseTree(ref: "origin/main"), exitCode: 0, output: mainTree),
            result(.mergeTreeWriteTree(base: "origin/main", branch: "feature/login"), exitCode: 0, output: mainTree)
        ])

        #expect(try sut.contentMergedBranches(["feature/login"], into: "origin/main", at: testRepoPath) == ["feature/login"])
    }

    @Test
    func `A branch whose merge would change the ref's tree is not merged`() throws {
        let sut = makeSUT(gitResults: [
            result(.revParseTree(ref: "origin/main"), exitCode: 0, output: mainTree),
            result(.mergeTreeWriteTree(base: "origin/main", branch: "feature/login"), exitCode: 0, output: "9f1c2e7a5b3d4c6e8f0a1b2c3d4e5f6a7b8c9d0e")
        ])

        #expect(try sut.contentMergedBranches(["feature/login"], into: "origin/main", at: testRepoPath).isEmpty)
    }

    @Test
    func `A branch that conflicts with the ref is not merged`() throws {
        let conflictOutput = "\(mainTree)\n100644 abc 1\tREADME.md\n\nCONFLICT (content): Merge conflict in README.md"
        let sut = makeSUT(gitResults: [
            result(.revParseTree(ref: "origin/main"), exitCode: 0, output: mainTree),
            result(.mergeTreeWriteTree(base: "origin/main", branch: "feature/login"), exitCode: 1, output: conflictOutput)
        ])

        #expect(try sut.contentMergedBranches(["feature/login"], into: "origin/main", at: testRepoPath).isEmpty)
    }

    @Test
    func `A git without merge-tree --write-tree reports no branches as merged`() throws {
        let sut = makeSUT(gitResults: [
            result(.revParseTree(ref: "origin/main"), exitCode: 0, output: mainTree),
            result(.mergeTreeWriteTree(base: "origin/main", branch: "feature/login"), exitCode: 129, output: "usage: git merge-tree <base-tree> <branch1> <branch2>")
        ])

        #expect(try sut.contentMergedBranches(["feature/login"], into: "origin/main", at: testRepoPath).isEmpty)
    }

    @Test
    func `A ref that doesn't resolve reports no branches as merged without trying any merge`() throws {
        let sut = makeSUT(gitResults: [result(.revParseTree(ref: "origin/main"), exitCode: 1, output: "")])

        #expect(try sut.contentMergedBranches(["feature/login"], into: "origin/main", at: testRepoPath).isEmpty)
    }

    @Test
    func `Only the branches already in the ref are reported, in the order given`() throws {
        let sut = makeSUT(gitResults: [
            result(.revParseTree(ref: "origin/main"), exitCode: 0, output: mainTree),
            result(.mergeTreeWriteTree(base: "origin/main", branch: "feature/a"), exitCode: 0, output: mainTree),
            result(.mergeTreeWriteTree(base: "origin/main", branch: "feature/b"), exitCode: 0, output: "9f1c2e7a5b3d4c6e8f0a1b2c3d4e5f6a7b8c9d0e"),
            result(.mergeTreeWriteTree(base: "origin/main", branch: "feature/c"), exitCode: 0, output: mainTree)
        ])

        let merged = try sut.contentMergedBranches(["feature/a", "feature/b", "feature/c"], into: "origin/main", at: testRepoPath)

        #expect(merged == ["feature/a", "feature/c"])
    }

    @Test
    func `Merged branches are read for each candidate ref, leaving out refs that don't resolve`() throws {
        let sut = makeSUT(gitResults: [
            result(.mergedBranches(ref: "origin/main"), exitCode: 0, output: "main\nfeature/a\n"),
            result(.mergedBranches(ref: "upstream/main"), exitCode: 128, output: "fatal: malformed object name upstream/main")
        ])

        let merged = try sut.mergedByRef(candidateRefs: ["origin/main", "upstream/main"], at: testRepoPath)

        #expect(merged == ["origin/main": ["main", "feature/a"]])
    }

    @Test
    func `Content merges are checked only for branches each ref hasn't merged`() throws {
        let sut = makeSUT(gitResults: [
            result(.revParseTree(ref: "origin/main"), exitCode: 0, output: mainTree),
            result(.mergeTreeWriteTree(base: "origin/main", branch: "squashed"), exitCode: 0, output: mainTree),
            result(.mergeTreeWriteTree(base: "origin/main", branch: "feature/b"), exitCode: 0, output: "other-tree")
        ])

        let contentMerged = try sut.contentMergedByRef(mergedByRef: ["origin/main": ["main"]], localBranchNames: ["main", "squashed", "feature/b"], at: testRepoPath)

        #expect(contentMerged == ["origin/main": ["squashed"]])
    }
}

// MARK: - Helpers
private extension GitClientMergedBranchesTests {
    var testRepoPath: String {
        return "/Users/dev/nngit"
    }

    var mainTree: String {
        return "3a247983d5372d3d195a08a8905eea1712cb881c"
    }

    func result(_ command: GitCommand, exitCode: Int32, output: String) -> MockGitCommandRunner.GitResult {
        return .init(command: command, path: testRepoPath, output: .init(exitCode: exitCode, output: output))
    }
}

// MARK: - SUT
private extension GitClientMergedBranchesTests {
    func makeSUT(gitResults: [MockGitCommandRunner.GitResult]) -> GitClient {
        return .init(runner: MockGitCommandRunner(gitResults: gitResults, gitHubResults: []))
    }
}
