// MARK: - Remotes
extension GitClient {
    public func remoteNames(at path: String) throws -> [String] {
        return try lines(of: runExpectingSuccess(.remote, at: path))
    }

    public func remoteURL(of remote: String, at path: String) throws -> String? {
        let result = try runner.runGit(.remoteGetURL(name: remote), at: path)

        guard result.exitCode == 0 else {
            return nil
        }

        let url = trimmed(result.output)

        return url.isEmpty ? nil : url
    }

    public func remoteHeadBranches(for remoteNames: [String], at path: String) throws -> [String: String] {
        var heads: [String: String] = [:]

        for remote in remoteNames {
            heads[remote] = try symbolicRef("refs/remotes/\(remote)/HEAD", at: path)
        }

        return heads
    }

    public func pushBranch(_ branch: String, to remote: String, at path: String) throws {
        try runExpectingSuccess(.pushBranch(remote: remote, branch: branch), at: path)
    }

    public func pushBranchSettingUpstream(_ branch: String, to remote: String, at path: String) throws {
        try runExpectingSuccess(.pushSettingUpstream(remote: remote, branch: branch), at: path)
    }

    public func setRemoteHead(_ branch: String, for remote: String, at path: String) throws {
        try runExpectingSuccess(.remoteSetHead(remote: remote, branch: branch), at: path)
    }

    public func pushTag(_ tag: String, to remote: String, at path: String) throws {
        try runExpectingSuccess(.pushTag(remote: remote, tag: tag), at: path)
    }

    public func pushHead(to remote: String, at path: String) throws {
        try runExpectingSuccess(.pushHead(remote: remote), at: path)
    }

    public func pullFastForward(at path: String) throws {
        try runExpectingSuccess(.pullFastForward, at: path)
    }

    public func fetchAllTags(at path: String) throws -> Bool {
        return try runner.runGit(.fetchAllTags, at: path).exitCode == 0
    }

    public func fetchAllPruned(at path: String) throws -> FetchResult {
        let result = try runner.runGit(.fetchAllPruned, at: path)

        guard result.exitCode == 0 else {
            return .failed(output: trimmed(result.output))
        }

        return .fetched
    }

    public func fastForward(to ref: String, at path: String) throws {
        try runExpectingSuccess(.mergeFastForward(ref: ref), at: path)
    }

    public func push(_ source: String, to destination: String, on remote: String, at path: String) throws {
        try runExpectingSuccess(.pushRefspec(remote: remote, source: source, destination: destination), at: path)
    }

    /// Pass `"HEAD"` as `branch` for the checked-out branch.
    public func commitsBehindUpstream(of branch: String, at path: String) throws -> Int? {
        let result = try runner.runGit(.revListCountBehindUpstream(branch: branch), at: path)

        guard result.exitCode == 0 else {
            return nil
        }

        return Int(trimmed(result.output))
    }

    /// Pass `"HEAD"` as `branch` for the checked-out branch.
    public func commitsAheadOfUpstream(of branch: String, at path: String) throws -> Int? {
        let result = try runner.runGit(.revListCountAheadOfUpstream(branch: branch), at: path)

        guard result.exitCode == 0 else {
            return nil
        }

        return Int(trimmed(result.output))
    }
}
