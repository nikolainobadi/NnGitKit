import Testing
import NnGitKit
import NnGitTesting

struct GitClientTrackingTests {
    @Test
    func `Tracked paths are split on NUL, keeping spaces in names`() throws {
        let sut = makeSUT(results: [(.lsFilesTracked, .init(exitCode: 0, output: " lead.txt\0src/a b.swift\0"))])

        #expect(try sut.trackedPaths(at: testRepoPath) == [" lead.txt", "src/a b.swift"])
    }

    @Test
    func `Ignored tracked paths are listed once each, in git's order`() throws {
        let sut = makeSUT(results: [(.lsFilesIgnoredTracked, .init(exitCode: 0, output: "build/out.o\0app.log\0app.log\0app.log\0"))])

        #expect(try sut.ignoredTrackedPaths(at: testRepoPath) == ["build/out.o", "app.log"])
    }

    @Test
    func `No ignored tracked paths reads as an empty list`() throws {
        let sut = makeSUT(results: [(.lsFilesIgnoredTracked, .init(exitCode: 0, output: ""))])

        #expect(try sut.ignoredTrackedPaths(at: testRepoPath) == [])
    }

    @Test
    func `Ignored untracked paths are split on NUL, keeping folder entries' trailing slash`() throws {
        let sut = makeSUT(results: [(.lsFilesIgnoredOthers, .init(exitCode: 0, output: ".env\0.build/\0Config/GoogleService-Info.plist\0"))])

        #expect(try sut.ignoredUntrackedPaths(at: testRepoPath) == [".env", ".build/", "Config/GoogleService-Info.plist"])
    }

    @Test
    func `No ignored untracked paths reads as an empty list`() throws {
        let sut = makeSUT(results: [(.lsFilesIgnoredOthers, .init(exitCode: 0, output: ""))])

        #expect(try sut.ignoredUntrackedPaths(at: testRepoPath) == [])
    }

    @Test
    func `A failed ignored untracked listing throws git's message`() {
        let sut = makeSUT(results: [(.lsFilesIgnoredOthers, .init(exitCode: 128, output: "fatal: not a git repository"))])

        let error = #expect(throws: GitError.self) {
            try sut.ignoredUntrackedPaths(at: testRepoPath)
        }

        expectFailure(error, command: .lsFilesIgnoredOthers, exitCode: 128, output: "fatal: not a git repository")
    }

    @Test
    func `A failed listing throws git's message`() {
        let sut = makeSUT(results: [(.lsFilesTracked, .init(exitCode: 128, output: "fatal: not a git repository"))])

        let error = #expect(throws: GitError.self) {
            try sut.trackedPaths(at: testRepoPath)
        }

        expectFailure(error, command: .lsFilesTracked, exitCode: 128, output: "fatal: not a git repository")
    }

    @Test
    func `Paths under the argument budget are removed in one call`() throws {
        let paths = ["build", "app.log", "sub/cache.tmp"]
        let sut = makeSUT(results: [(.removeCached(paths: paths), .init(exitCode: 0, output: ""))])

        try sut.removeFromIndex(paths: paths, at: testRepoPath)
    }

    @Test
    func `Paths over the argument budget are removed in several calls, in order`() throws {
        let first = longPath("a")
        let second = longPath("b")
        let third = longPath("c")
        let sut = makeSUT(results: [
            (.removeCached(paths: [first, second]), .init(exitCode: 0, output: "")),
            (.removeCached(paths: [third]), .init(exitCode: 0, output: ""))
        ])

        try sut.removeFromIndex(paths: [first, second, third], at: testRepoPath)
    }

    @Test
    func `A refused group stops the removal and throws git's message`() {
        let first = longPath("a")
        let second = longPath("b")
        let third = longPath("c")
        let refusal = "error: the following file has staged content different from both the file and the HEAD"
        let sut = makeSUT(results: [(.removeCached(paths: [first, second]), .init(exitCode: 1, output: refusal))])

        let error = #expect(throws: GitError.self) {
            try sut.removeFromIndex(paths: [first, second, third], at: testRepoPath)
        }

        expectFailure(error, command: .removeCached(paths: [first, second]), exitCode: 1, output: refusal)
    }

    @Test
    func `No paths runs nothing`() throws {
        let sut = makeSUT(results: [])

        try sut.removeFromIndex(paths: [], at: testRepoPath)
    }
}

// MARK: - Helpers
private extension GitClientTrackingTests {
    var testRepoPath: String {
        return "/Users/dev/nngit"
    }

    func longPath(_ prefix: String) -> String {
        return prefix + "/" + String(repeating: "x", count: 60_000)
    }

    func expectFailure(_ error: GitError?, command: GitCommand, exitCode: Int32, output: String) {
        guard case .commandFailed(let failedCommand, let failedExitCode, let failedOutput) = error else {
            Issue.record("Expected a failed command")
            return
        }

        #expect(failedCommand == command)
        #expect(failedExitCode == exitCode)
        #expect(failedOutput == output)
    }
}

// MARK: - SUT
private extension GitClientTrackingTests {
    func makeSUT(results: [(command: GitCommand, output: GitCommandOutput)]) -> GitClient {
        let gitResults = results.map { MockGitCommandRunner.GitResult(command: $0.command, path: testRepoPath, output: $0.output) }

        return .init(runner: MockGitCommandRunner(gitResults: gitResults, gitHubResults: []))
    }
}
