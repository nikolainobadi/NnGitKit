// MARK: - Status
extension GitClient {
    public func isAncestor(_ ancestor: String, of descendant: String, at path: String) throws -> Bool {
        return try runner.runGit(.isAncestor(ancestor: ancestor, descendant: descendant), at: path).exitCode == 0
    }

    public func repositoryRoot(at path: String) throws -> String? {
        let result = try runner.runGit(.revParseTopLevel, at: path)

        guard result.exitCode == 0 else {
            return nil
        }

        return trimmed(result.output)
    }

    public func repositoryRootLookup(at path: String) throws -> RepositoryRootLookup {
        let result = try runner.runGit(.revParseTopLevel, at: path)

        guard result.exitCode == 0 else {
            return .notFound(output: trimmed(result.output))
        }

        return .found(path: trimmed(result.output))
    }

    public func gitDirectory(at path: String) throws -> String {
        return try runExpectingSuccess(.revParseAbsoluteGitDir, at: path)
    }

    public func headCommit(at path: String) throws -> String? {
        let result = try runner.runGit(.revParseHead, at: path)

        guard result.exitCode == 0 else {
            return nil
        }

        return trimmed(result.output)
    }

    /// The commit a branch, tag, remote-tracking ref, or commit id resolves to, or `nil` when it resolves to none.
    public func commit(ofRevision revision: String, at path: String) throws -> String? {
        let result = try runner.runGit(.revParseCommit(ref: revision), at: path)

        guard result.exitCode == 0 else {
            return nil
        }

        return trimmed(result.output)
    }

    public func commitCount(since commit: String, at path: String) throws -> Int? {
        let result = try runner.runGit(.revListCount(since: commit), at: path)

        guard result.exitCode == 0 else {
            return nil
        }

        return Int(trimmed(result.output))
    }

    public func isIgnored(path relativePath: String, at path: String) throws -> Bool {
        let result = try runner.runGit(.checkIgnore(path: relativePath), at: path)

        switch result.exitCode {
        case 0:
            return true
        case 1:
            return false
        default:
            throw GitError.commandFailed(command: .checkIgnore(path: relativePath), exitCode: result.exitCode, output: result.output)
        }
    }

    public func hasUncommittedChanges(at path: String) throws -> Bool {
        return try !runExpectingSuccess(.statusPorcelain, at: path).isEmpty
    }

    public func uncommittedPaths(at path: String) throws -> [String] {
        return try statusPaths(at: path).map(\.path)
    }

    public func untrackedPaths(at path: String) throws -> [String] {
        return try statusPaths(at: path).filter({ $0.kind == .untracked }).map(\.path)
    }

    public func uncommittedFiles(at path: String) throws -> [UncommittedFile] {
        return try statusEntries(command: .statusPorcelainCollapsed, at: path).map { $0.entry.makeUncommittedFile(originalPath: $0.originalPath) }
    }

    public func uncommittedFileCounts(at path: String) throws -> UncommittedFileCounts {
        let changes = try statusEntries(command: .statusPorcelainPaths, at: path).map(\.entry.change)

        return .init(
            added: changes.filter({ $0 == .added }).count,
            modified: changes.filter({ $0 == .modified }).count,
            deleted: changes.filter({ $0 == .deleted }).count
        )
    }

    public func pathsRestoredByReset(to target: String, at path: String) throws -> [String] {
        return nullSeparated(try runExpectingSuccess(.diffPathsMissingFromHead(target: target), at: path))
    }

    public func unversionedPaths(overlapping paths: [String], ignoringCase: Bool, at path: String) throws -> [String] {
        guard !paths.isEmpty else {
            return []
        }

        let pathspecs = ignoringCase ? [] : pathsWithParentFolders(paths)

        return nullSeparated(try runExpectingSuccess(.lsFilesOthers(paths: pathspecs), at: path))
    }

    public func fileNamesIgnoreCase(at path: String) throws -> Bool {
        return try ["true", "yes", "on", "1"].contains(configValue(for: "core.ignorecase", at: path)?.lowercased())
    }

    /// Commits reachable from `tip` but not from `base`, or `nil` when either ref can't be resolved.
    public func commitCount(from base: String, to tip: String, at path: String) throws -> Int? {
        let result = try runner.runGit(.revListCountRange(base: base, tip: tip), at: path)

        guard result.exitCode == 0 else {
            return nil
        }

        return Int(trimmed(result.output))
    }
}

// MARK: - Private Methods
private extension GitClient {
    func nullSeparated(_ output: String) -> [String] {
        return output.split(separator: "\0").map(String.init).filter { !trimmed($0).isEmpty }
    }

    func pathsWithParentFolders(_ paths: [String]) -> [String] {
        var seen = Set<String>()
        var expanded: [String] = []

        for path in paths {
            let components = path.split(separator: "/")

            for index in components.indices {
                let prefix = components[...index].joined(separator: "/")

                if seen.insert(prefix).inserted {
                    expanded.append(prefix)
                }
            }
        }

        return expanded
    }

    func statusPaths(at path: String) throws -> [(kind: StatusEntry.Kind, path: String)] {
        var paths: [(kind: StatusEntry.Kind, path: String)] = []

        for (entry, originalPath) in try statusEntries(command: .statusPorcelainPaths, at: path) {
            paths.append((kind: entry.kind, path: entry.path))

            if let originalPath {
                paths.append((kind: entry.kind, path: originalPath))
            }
        }

        return paths
    }

    func statusEntries(command: GitCommand, at path: String) throws -> [(entry: StatusEntry, originalPath: String?)] {
        let fields = try runExpectingSuccess(command, at: path).split(separator: "\0").map(String.init)
        var entries: [(entry: StatusEntry, originalPath: String?)] = []
        var index = fields.startIndex

        while index < fields.endIndex {
            let entry = StatusEntry(fields[index])

            if let entry, entry.kind == .renamed, fields.indices.contains(index + 1) {
                entries.append((entry: entry, originalPath: fields[index + 1]))
                index += 2
            } else {
                if let entry {
                    entries.append((entry: entry, originalPath: nil))
                }

                index += 1
            }
        }

        return entries
    }
}

// MARK: - StatusEntry
private struct StatusEntry {
    let kind: Kind
    let path: String
    let statusCode: Substring
    let headMode: Substring?

    init?(_ entry: String) {
        guard let kind = Kind.allCases.first(where: { entry.hasPrefix($0.prefix) }) else {
            return nil
        }

        let fields = entry.split(separator: " ", maxSplits: kind.fieldCount - 1, omittingEmptySubsequences: false)

        guard fields.count == kind.fieldCount, let path = fields.last else {
            return nil
        }

        self.kind = kind
        self.path = String(path)
        self.statusCode = fields[1]
        self.headMode = kind.headModeFieldIndex.map { fields[$0] }
    }

    func makeUncommittedFile(originalPath: String?) -> UncommittedFile {
        let conflicted = kind == .unmerged
        let untracked = kind == .untracked

        return .init(
            path: path,
            originalPath: originalPath,
            hasStagedChanges: conflicted || statusCode.first.map { !untracked && $0 != "." } ?? false,
            hasUnstagedChanges: conflicted || untracked || statusCode.last != ".",
            untracked: untracked,
            conflicted: conflicted,
            existsInHead: headMode.map { $0 != Self.missingMode } ?? false,
            change: change
        )
    }

    var change: UncommittedFile.Change {
        switch kind {
        case .untracked:
            return .added
        case .unmerged:
            return .modified
        case .ordinary, .renamed:
            if statusCode.contains("D") {
                return .deleted
            }

            return statusCode.contains("A") ? .added : .modified
        }
    }

    private static let missingMode: Substring = "000000"

    enum Kind: CaseIterable {
        case ordinary
        case renamed
        case unmerged
        case untracked

        var prefix: String {
            switch self {
            case .ordinary:
                return "1 "
            case .renamed:
                return "2 "
            case .unmerged:
                return "u "
            case .untracked:
                return "? "
            }
        }

        var fieldCount: Int {
            switch self {
            case .ordinary:
                return 9
            case .renamed:
                return 10
            case .unmerged:
                return 11
            case .untracked:
                return 2
            }
        }

        var headModeFieldIndex: Int? {
            switch self {
            case .ordinary, .renamed:
                return 3
            case .unmerged:
                return 4
            case .untracked:
                return nil
            }
        }
    }
}
