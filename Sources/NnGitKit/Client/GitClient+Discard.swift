// MARK: - Discard
extension GitClient {
    public func unstageAll(at path: String) throws {
        try runExpectingSuccess(.resetIndex, at: path)
    }

    public func unstage(paths: [String], at path: String) throws {
        try runExpectingSuccess(.resetIndexPaths(paths: paths), at: path)
    }

    public func resetHardToHead(at path: String) throws {
        try runExpectingSuccess(.resetHardHead, at: path)
    }

    public func restoreWorktree(at path: String) throws {
        try runExpectingSuccess(.restoreWorktree, at: path)
    }

    public func restoreFromIndex(path relativePath: String, at path: String) throws {
        try runExpectingSuccess(.restoreFromIndex(path: relativePath), at: path)
    }

    public func restoreFromHead(path relativePath: String, at path: String) throws {
        try runExpectingSuccess(.restoreFromHead(path: relativePath), at: path)
    }

    public func cleanUntracked(at path: String) throws {
        try runExpectingSuccess(.cleanUntracked, at: path)
    }

    public func cleanUntracked(path relativePath: String, at path: String) throws {
        try runExpectingSuccess(.cleanPath(path: relativePath), at: path)
    }
}
