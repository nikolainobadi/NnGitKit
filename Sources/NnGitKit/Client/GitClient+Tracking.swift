// MARK: - Tracking
extension GitClient {
    public func trackedPaths(at path: String) throws -> [String] {
        return try pathList(.lsFilesTracked, at: path)
    }

    public func ignoredTrackedPaths(at path: String) throws -> [String] {
        var seen = Set<String>()

        return try pathList(.lsFilesIgnoredTracked, at: path).filter { seen.insert($0).inserted }
    }

    public func removeFromIndex(paths: [String], at path: String) throws {
        for group in removalGroups(of: paths) {
            try runExpectingSuccess(.removeCached(paths: group), at: path)
        }
    }
}

// MARK: - Private Methods
private extension GitClient {
    static let removalArgumentBudget = 128 * 1024

    func pathList(_ command: GitCommand, at path: String) throws -> [String] {
        let result = try runner.runGit(command, at: path)

        guard result.exitCode == 0 else {
            throw GitError.commandFailed(command: command, exitCode: result.exitCode, output: result.output)
        }

        return result.output.split(separator: "\0").map(String.init).filter { !$0.isEmpty }
    }

    func removalGroups(of paths: [String]) -> [[String]] {
        var groups: [[String]] = []
        var current: [String] = []
        var currentBytes = 0

        for path in paths {
            let bytes = path.utf8.count + 1

            if !current.isEmpty && currentBytes + bytes > Self.removalArgumentBudget {
                groups.append(current)
                current = []
                currentBytes = 0
            }

            current.append(path)
            currentBytes += bytes
        }

        if !current.isEmpty {
            groups.append(current)
        }

        return groups
    }
}
