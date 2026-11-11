import Testing
import NnGitKit
import NnGitTesting

struct GitClientActivityTests {
    @Test
    func `Each commit record becomes its files with line counts`() throws {
        let output = record(sha: "abc123", day: "2026-11-07", rows: ["3\t1\tSources/App.swift", "10\t0\tTests/AppTests.swift"]) + record(sha: "def456", day: "2026-11-06", rows: ["0\t4\tREADME.md"])
        let sut = makeSUT(output: .init(exitCode: 0, output: output))

        let commits = try sut.commitActivity(refs: testRefs, since: testSince, author: nil, at: testRepoPath)

        #expect(commits == [
            .init(shortSha: "abc123", day: "2026-11-07", files: [
                .init(path: "Sources/App.swift", added: 3, deleted: 1),
                .init(path: "Tests/AppTests.swift", added: 10, deleted: 0)
            ]),
            .init(shortSha: "def456", day: "2026-11-06", files: [
                .init(path: "README.md", added: 0, deleted: 4)
            ])
        ])
    }

    @Test
    func `A binary file has no line counts`() throws {
        let sut = makeSUT(output: .init(exitCode: 0, output: record(sha: "abc123", day: "2026-11-07", rows: ["-\t-\tAssets/icon.png"])))

        let files = try sut.commitActivity(refs: testRefs, since: testSince, author: nil, at: testRepoPath).flatMap(\.files)

        #expect(files == [.init(path: "Assets/icon.png", added: nil, deleted: nil)])
    }

    @Test
    func `A path with spaces stays whole`() throws {
        let sut = makeSUT(output: .init(exitCode: 0, output: record(sha: "abc123", day: "2026-11-07", rows: ["1\t1\tDocs/Release Notes.md"])))

        let files = try sut.commitActivity(refs: testRefs, since: testSince, author: nil, at: testRepoPath).flatMap(\.files)

        #expect(files.map(\.path) == ["Docs/Release Notes.md"])
    }

    @Test
    func `A commit that changes no files has an empty file list`() throws {
        let sut = makeSUT(output: .init(exitCode: 0, output: record(sha: "abc123", day: "2026-11-07", rows: [])))

        let commits = try sut.commitActivity(refs: testRefs, since: testSince, author: nil, at: testRepoPath)

        #expect(commits == [.init(shortSha: "abc123", day: "2026-11-07", files: [])])
    }

    @Test
    func `No output means no commits`() throws {
        let sut = makeSUT(output: .init(exitCode: 0, output: ""))

        #expect(try sut.commitActivity(refs: testRefs, since: testSince, author: nil, at: testRepoPath).isEmpty)
    }

    @Test
    func `The author filter reaches git`() throws {
        let command = GitCommand.logActivity(refs: testRefs, since: testSince, author: "dev@example.com")
        let runner = RecordingGitCommandRunner(gitResults: [.init(command: command, path: testRepoPath, output: .init(exitCode: 0, output: ""))], gitHubResults: [])
        let sut = GitClient(runner: runner)

        _ = try sut.commitActivity(refs: testRefs, since: testSince, author: "dev@example.com", at: testRepoPath)

        #expect(runner.gitCommands == [command])
    }

    @Test(arguments: [
        "\u{1e}abc123\n1\t1\tfile.swift\n",
        "\u{1e}abc123\u{0}\n",
        "\u{1e}abc123\u{0}2026-11-07\u{0}extra\n"
    ])
    func `A record header that can't be read throws`(output: String) {
        let sut = makeSUT(output: .init(exitCode: 0, output: output))

        let error = #expect(throws: GitError.self) {
            try sut.commitActivity(refs: testRefs, since: testSince, author: nil, at: testRepoPath)
        }

        guard case .unreadableOutput(let command, _) = error else {
            Issue.record("Expected unreadable output")
            return
        }

        #expect(command == .logActivity(refs: testRefs, since: testSince, author: nil))
    }

    @Test(arguments: [
        "1\tfile.swift",
        "x\t1\tfile.swift",
        "1\t-x\tfile.swift",
        "1\t1\t"
    ])
    func `A file row that can't be read throws instead of being dropped`(row: String) {
        let sut = makeSUT(output: .init(exitCode: 0, output: record(sha: "abc123", day: "2026-11-07", rows: [row, "1\t1\tvalid.swift"])))

        let error = #expect(throws: GitError.self) {
            try sut.commitActivity(refs: testRefs, since: testSince, author: nil, at: testRepoPath)
        }

        guard case .unreadableOutput(_, let unreadable) = error else {
            Issue.record("Expected unreadable output")
            return
        }

        #expect(unreadable == row)
    }

    @Test
    func `A log git refuses throws git's message`() {
        let sut = makeSUT(output: .init(exitCode: 128, output: "fatal: your current branch 'main' does not have any commits yet"))

        let error = #expect(throws: GitError.self) {
            try sut.commitActivity(refs: testRefs, since: testSince, author: nil, at: testRepoPath)
        }

        guard case .commandFailed(_, let exitCode, let output) = error else {
            Issue.record("Expected a failed command")
            return
        }

        #expect(exitCode == 128)
        #expect(output == "fatal: your current branch 'main' does not have any commits yet")
    }
}

// MARK: - Helpers
private extension GitClientActivityTests {
    var testRepoPath: String {
        return "/Users/dev/nngit"
    }

    var testRefs: [String] {
        return ["main", "HEAD"]
    }

    var testSince: String {
        return "2026-11-05 00:00"
    }

    func record(sha: String, day: String, rows: [String]) -> String {
        let body = rows.isEmpty ? "" : "\n\n" + rows.joined(separator: "\n")

        return "\u{1e}\(sha)\u{0}\(day)" + body + "\n"
    }
}

// MARK: - SUT
private extension GitClientActivityTests {
    func makeSUT(output: GitCommandOutput) -> GitClient {
        let command = GitCommand.logActivity(refs: testRefs, since: testSince, author: nil)
        let runner = MockGitCommandRunner(gitResults: [.init(command: command, path: testRepoPath, output: output)], gitHubResults: [])

        return .init(runner: runner)
    }
}
