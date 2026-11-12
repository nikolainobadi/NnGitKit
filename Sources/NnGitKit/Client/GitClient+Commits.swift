// MARK: - Commits
extension GitClient {
    public func stageAll(at path: String) throws {
        try runExpectingSuccess(.addAll, at: path)
    }

    public func commit(message: String, at path: String) throws {
        try runExpectingSuccess(.commit(message: message), at: path)
    }

    public func commitAllowingEmpty(message: String, at path: String) throws {
        try runExpectingSuccess(.commitAllowingEmpty(message: message), at: path)
    }

    public func indexTree(at path: String) throws -> String {
        return try runExpectingSuccess(.writeTree, at: path)
    }

    public func restoreIndex(toTree tree: String, at path: String) throws {
        try runExpectingSuccess(.readTree(tree: tree), at: path)
    }

    public func stagedDiff(at path: String) throws -> String {
        return try runExpectingSuccess(.diffCached, at: path)
    }

    public func commitSummaries(in range: String, at path: String) throws -> [String] {
        return try lines(of: runExpectingSuccess(.logOneline(range: range), at: path))
    }

    public func commitMessages(since revision: String?, paths: [String], at path: String) throws -> [String] {
        return try runExpectingSuccess(.logMessages(since: revision, paths: paths), at: path)
            .split(separator: "\u{1e}")
            .map { trimmed(String($0)) }
            .filter { !$0.isEmpty }
    }

    public func recentCommits(limit: Int, at path: String) throws -> [CommitSummary] {
        let command = GitCommand.logFirstParent(limit: limit)

        return try runExpectingSuccess(command, at: path)
            .split(separator: "\u{1e}")
            .map { try commitSummary(from: trimmed(String($0)), command: command) }
    }

    public func commitActivity(refs: [String], since: String, author: String?, at path: String) throws -> [CommitActivity] {
        let command = GitCommand.logActivity(refs: refs, since: since, author: author)

        return try runExpectingSuccess(command, at: path)
            .split(separator: "\u{1e}")
            .map { trimmed(String($0)) }
            .filter { !$0.isEmpty }
            .map { try commitActivity(from: $0, command: command) }
    }

    public func commitChanges(in range: String, at path: String) throws -> [CommitChanges] {
        let command = GitCommand.logCommitChanges(range: range)

        return try runExpectingSuccess(command, at: path)
            .split(separator: "\u{1e}")
            .map { trimmed(String($0)) }
            .filter { !$0.isEmpty }
            .map { try commitChanges(from: $0, command: command) }
    }
}

// MARK: - Private Methods
private extension GitClient {
    static let binaryLineCount = "-"

    func commitSummary(from record: String, command: GitCommand) throws -> CommitSummary {
        let fields = record.split(separator: "\0", omittingEmptySubsequences: false).map(String.init)

        guard fields.count == 7 else {
            throw GitError.unreadableOutput(command: command, output: record)
        }

        return .init(
            sha: fields[0],
            shortSha: fields[1],
            subject: fields[2],
            authorName: fields[3],
            authorEmail: fields[4],
            relativeDate: fields[5],
            parentCount: fields[6].split(separator: " ").count
        )
    }

    func commitActivity(from record: String, command: GitCommand) throws -> CommitActivity {
        let recordLines = lines(of: record)
        let header = recordLines.first?.split(separator: "\0", omittingEmptySubsequences: false).map(String.init) ?? []

        guard header.count == 2, !header[0].isEmpty, !header[1].isEmpty else {
            throw GitError.unreadableOutput(command: command, output: record)
        }

        return .init(
            shortSha: header[0],
            day: header[1],
            files: try recordLines.dropFirst().map { try fileChange(from: $0, command: command) }
        )
    }

    func fileChange(from line: String, command: GitCommand) throws -> FileChange {
        let columns = line.split(separator: "\t", maxSplits: 2, omittingEmptySubsequences: false).map(String.init)

        guard columns.count == 3, !columns[2].isEmpty, isLineCount(columns[0]), isLineCount(columns[1]) else {
            throw GitError.unreadableOutput(command: command, output: line)
        }

        return .init(path: columns[2], added: Int(columns[0]), deleted: Int(columns[1]))
    }

    func isLineCount(_ column: String) -> Bool {
        return column == Self.binaryLineCount || Int(column) != nil
    }
}

// MARK: - Commit Changes
private extension GitClient {
    static let createdPrefix = "create mode "
    static let deletedPrefix = "delete mode "
    static let summaryIndent = " "

    func commitChanges(from record: String, command: GitCommand) throws -> CommitChanges {
        let recordLines = lines(of: record)
        let header = recordLines.first?.split(separator: "\0", omittingEmptySubsequences: false).map(String.init) ?? []

        guard header.count == 3, !header[0].isEmpty, !header[1].isEmpty else {
            throw GitError.unreadableOutput(command: command, output: record)
        }

        var files: [FileChange] = []
        var createdPaths: [String] = []
        var deletedPaths: [String] = []

        for line in recordLines.dropFirst() {
            if line.contains("\t") {
                files.append(try fileChange(from: line, command: command))
            } else if line.hasPrefix(Self.summaryIndent) {
                let summary = String(line.drop(while: { $0 == " " }))

                if let created = try summaryPath(of: summary, prefix: Self.createdPrefix, command: command) {
                    createdPaths.append(created)
                } else if let deleted = try summaryPath(of: summary, prefix: Self.deletedPrefix, command: command) {
                    deletedPaths.append(deleted)
                }
            } else {
                throw GitError.unreadableOutput(command: command, output: line)
            }
        }

        return .init(shortSha: header[0], date: header[1], subject: header[2], files: files, createdPaths: createdPaths, deletedPaths: deletedPaths)
    }

    func summaryPath(of summary: String, prefix: String, command: GitCommand) throws -> String? {
        guard summary.hasPrefix(prefix) else {
            return nil
        }

        let modeAndPath = summary.dropFirst(prefix.count).split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)

        guard modeAndPath.count == 2, !modeAndPath[1].isEmpty else {
            throw GitError.unreadableOutput(command: command, output: summary)
        }

        return String(modeAndPath[1])
    }
}
