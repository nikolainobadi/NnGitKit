import Testing
import NnGitKit
import NnGitTesting

struct GitClientCommitChangesTests {
    @Test
    func `Each commit record becomes its subject, files, and created and deleted paths`() throws {
        let output = record(
            sha: "abc123",
            date: "2026-11-10",
            subject: "Add the parser",
            rows: ["12\t0\tSources/Parser.swift", "3\t1\tSources/App.swift", "0\t9\tSources/Old.swift"],
            summary: [" create mode 100644 Sources/Parser.swift", " delete mode 100644 Sources/Old.swift"]
        ) + record(sha: "def456", date: "2026-11-11", subject: "Tidy README", rows: ["1\t1\tREADME.md"], summary: [])
        let sut = makeSUT(output: .init(exitCode: 0, output: output))

        let commits = try sut.commitChanges(in: testRange, at: testRepoPath)

        #expect(commits == [
            .init(
                shortSha: "abc123",
                date: "2026-11-10",
                subject: "Add the parser",
                files: [
                    .init(path: "Sources/Parser.swift", added: 12, deleted: 0),
                    .init(path: "Sources/App.swift", added: 3, deleted: 1),
                    .init(path: "Sources/Old.swift", added: 0, deleted: 9)
                ],
                createdPaths: ["Sources/Parser.swift"],
                deletedPaths: ["Sources/Old.swift"]
            ),
            .init(shortSha: "def456", date: "2026-11-11", subject: "Tidy README", files: [.init(path: "README.md", added: 1, deleted: 1)], createdPaths: [], deletedPaths: [])
        ])
    }

    @Test
    func `A binary file has no line counts`() throws {
        let sut = makeSUT(output: .init(exitCode: 0, output: record(sha: "abc123", date: "2026-11-10", subject: "Add icon", rows: ["-\t-\tAssets/icon.png"], summary: [" create mode 100644 Assets/icon.png"])))

        let commit = try #require(try sut.commitChanges(in: testRange, at: testRepoPath).first)

        #expect(commit.files == [.init(path: "Assets/icon.png", added: nil, deleted: nil)])
        #expect(commit.createdPaths == ["Assets/icon.png"])
    }

    @Test
    func `Paths and subjects with spaces stay whole`() throws {
        let sut = makeSUT(output: .init(exitCode: 0, output: record(sha: "abc123", date: "2026-11-10", subject: "Write the release notes", rows: ["4\t0\tDocs/Release Notes.md"], summary: [" create mode 100644 Docs/Release Notes.md"])))

        let commit = try #require(try sut.commitChanges(in: testRange, at: testRepoPath).first)

        #expect(commit.subject == "Write the release notes")
        #expect(commit.files.map(\.path) == ["Docs/Release Notes.md"])
        #expect(commit.createdPaths == ["Docs/Release Notes.md"])
    }

    @Test
    func `A mode change is not a created or deleted path`() throws {
        let sut = makeSUT(output: .init(exitCode: 0, output: record(sha: "abc123", date: "2026-11-10", subject: "Make script executable", rows: ["0\t0\tscript.sh"], summary: [" mode change 100644 => 100755 script.sh"])))

        let commit = try #require(try sut.commitChanges(in: testRange, at: testRepoPath).first)

        #expect(commit.files == [.init(path: "script.sh", added: 0, deleted: 0)])
        #expect(commit.createdPaths.isEmpty)
        #expect(commit.deletedPaths.isEmpty)
    }

    @Test
    func `A commit that changes no files has empty lists`() throws {
        let sut = makeSUT(output: .init(exitCode: 0, output: record(sha: "abc123", date: "2026-11-10", subject: "Empty", rows: [], summary: [])))

        let commits = try sut.commitChanges(in: testRange, at: testRepoPath)

        #expect(commits == [.init(shortSha: "abc123", date: "2026-11-10", subject: "Empty", files: [], createdPaths: [], deletedPaths: [])])
    }

    @Test
    func `An empty subject is kept`() throws {
        let sut = makeSUT(output: .init(exitCode: 0, output: record(sha: "abc123", date: "2026-11-10", subject: "", rows: ["1\t0\ta.swift"], summary: [])))

        let commit = try #require(try sut.commitChanges(in: testRange, at: testRepoPath).first)

        #expect(commit.subject == "")
    }

    @Test
    func `No output means no commits`() throws {
        let sut = makeSUT(output: .init(exitCode: 0, output: ""))

        #expect(try sut.commitChanges(in: testRange, at: testRepoPath).isEmpty)
    }

    @Test
    func `The range reaches git`() throws {
        let command = GitCommand.logCommitChanges(range: testRange)
        let runner = RecordingGitCommandRunner(gitResults: [.init(command: command, path: testRepoPath, output: .init(exitCode: 0, output: ""))], gitHubResults: [])
        let sut = GitClient(runner: runner)

        _ = try sut.commitChanges(in: testRange, at: testRepoPath)

        #expect(runner.gitCommands == [command])
    }

    @Test(arguments: [
        "\u{1e}abc123\u{0}2026-11-10\n",
        "\u{1e}abc123\u{0}\u{0}subject\n",
        "\u{1e}\u{0}2026-11-10\u{0}subject\n",
        "\u{1e}abc123\u{0}2026-11-10\u{0}subject\u{0}extra\n"
    ])
    func `A record header that can't be read throws`(output: String) {
        let sut = makeSUT(output: .init(exitCode: 0, output: output))

        let error = #expect(throws: GitError.self) {
            try sut.commitChanges(in: testRange, at: testRepoPath)
        }

        guard case .unreadableOutput(let command, _) = error else {
            Issue.record("Expected unreadable output")
            return
        }

        #expect(command == .logCommitChanges(range: testRange))
    }

    @Test(arguments: [
        "1\tfile.swift",
        "x\t1\tfile.swift",
        "1\t1\t",
        "unexpected line"
    ])
    func `A body line that can't be read throws instead of being dropped`(row: String) {
        let sut = makeSUT(output: .init(exitCode: 0, output: record(sha: "abc123", date: "2026-11-10", subject: "s", rows: [row, "1\t1\tvalid.swift"], summary: [])))

        let error = #expect(throws: GitError.self) {
            try sut.commitChanges(in: testRange, at: testRepoPath)
        }

        guard case .unreadableOutput(_, let unreadable) = error else {
            Issue.record("Expected unreadable output")
            return
        }

        #expect(unreadable == row)
    }

    @Test(arguments: [" create mode 100644", " delete mode 100644 "])
    func `A created or deleted line without a path throws`(line: String) {
        let sut = makeSUT(output: .init(exitCode: 0, output: record(sha: "abc123", date: "2026-11-10", subject: "s", rows: ["1\t1\tvalid.swift"], summary: [line])))

        #expect(throws: GitError.self) {
            try sut.commitChanges(in: testRange, at: testRepoPath)
        }
    }

    @Test
    func `A log git refuses throws git's message`() {
        let sut = makeSUT(output: .init(exitCode: 128, output: "fatal: bad revision 'nope..HEAD'"))

        let error = #expect(throws: GitError.self) {
            try sut.commitChanges(in: testRange, at: testRepoPath)
        }

        guard case .commandFailed(_, let exitCode, let output) = error else {
            Issue.record("Expected a failed command")
            return
        }

        #expect(exitCode == 128)
        #expect(output == "fatal: bad revision 'nope..HEAD'")
    }
}

// MARK: - Helpers
private extension GitClientCommitChangesTests {
    var testRepoPath: String {
        return "/Users/dev/nngit"
    }

    var testRange: String {
        return "origin/main..HEAD"
    }

    func record(sha: String, date: String, subject: String, rows: [String], summary: [String]) -> String {
        let bodyLines = rows + summary
        let body = bodyLines.isEmpty ? "" : "\n\n" + bodyLines.joined(separator: "\n")

        return "\u{1e}\(sha)\u{0}\(date)\u{0}\(subject)" + body + "\n"
    }
}

// MARK: - SUT
private extension GitClientCommitChangesTests {
    func makeSUT(output: GitCommandOutput) -> GitClient {
        let command = GitCommand.logCommitChanges(range: testRange)
        let runner = MockGitCommandRunner(gitResults: [.init(command: command, path: testRepoPath, output: output)], gitHubResults: [])

        return .init(runner: runner)
    }
}
