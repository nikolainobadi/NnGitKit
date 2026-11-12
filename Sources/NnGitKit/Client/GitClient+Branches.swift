// MARK: - Branches
extension GitClient {
    public func currentBranch(at path: String) throws -> String? {
        let branch = try runExpectingSuccess(.branchShowCurrent, at: path)

        return branch.isEmpty ? nil : branch
    }

    public func localBranchNames(at path: String) throws -> [String] {
        return try lines(of: runExpectingSuccess(.localBranchRefs, at: path))
    }

    public func remoteBranchNames(at path: String) throws -> [String] {
        return try lines(of: runExpectingSuccess(.remoteBranchRefs, at: path)).filter { !$0.hasSuffix(Self.remoteHeadSuffix) }
    }

    public func upstream(of branch: String, at path: String) throws -> BranchUpstream? {
        let fields = try runExpectingSuccess(.upstreamDetails(branch: branch), at: path)
            .split(separator: "\0", omittingEmptySubsequences: false)
            .map(String.init)

        guard fields.count == Self.upstreamFieldCount, !fields[0].isEmpty else {
            return nil
        }

        return .init(
            name: fields[0],
            remote: fields[1],
            mergeRef: fields[2],
            remoteBranchIsGone: fields[3] == Self.goneTrack
        )
    }

    public func symbolicRef(_ ref: String, at path: String) throws -> String? {
        let result = try runner.runGit(.symbolicRefShort(ref: ref), at: path)

        guard result.exitCode == 0 else {
            return nil
        }

        let target = trimmed(result.output)

        return target.isEmpty ? nil : target
    }

    public func createAndSwitchToBranch(_ branch: String, at path: String) throws {
        try runExpectingSuccess(.switchCreate(branch: branch), at: path)
    }

    public func moveBranch(_ branch: String, to target: String, at path: String) throws {
        try runExpectingSuccess(.branchForce(branch: branch, target: target), at: path)
    }

    /// Every local branch with the worktree holding it and how it stands against its upstream, from one `git` call.
    public func localBranches(at path: String) throws -> [LocalBranch] {
        return try lines(of: runExpectingSuccess(.localBranchDetails, at: path)).compactMap(localBranch(from:))
    }

    public func switchToBranch(_ branch: String, at path: String) throws {
        try runExpectingSuccess(.switchBranch(branch: branch), at: path)
    }

    /// Creates a local branch named after `remoteBranch` (such as `origin/login`) that tracks it, and switches to it.
    public func switchToNewTrackingBranch(for remoteBranch: String, at path: String) throws {
        try runExpectingSuccess(.switchTrack(remoteBranch: remoteBranch), at: path)
    }

    /// Deletes the branch whether or not git considers it merged; the caller is responsible for that check.
    public func deleteBranch(_ branch: String, at path: String) throws {
        try runExpectingSuccess(.deleteBranchForce(branch: branch), at: path)
    }

    /// The commit a local branch points at, or `nil` when no such branch exists.
    public func commit(of branch: String, at path: String) throws -> String? {
        let result = try runner.runGit(.revParseCommit(ref: "refs/heads/\(branch)"), at: path)

        guard result.exitCode == 0 else {
            return nil
        }

        return trimmed(result.output)
    }

    /// Local branches whose commits are all reachable from `ref`, or `nil` when `ref` doesn't resolve.
    public func branchNames(mergedInto ref: String, at path: String) throws -> [String]? {
        let result = try runner.runGit(.mergedBranches(ref: ref), at: path)

        guard result.exitCode == 0 else {
            return nil
        }

        return lines(of: trimmed(result.output))
    }

    /// The branches whose changes are already in `ref` even though their commits aren't, as after a squash,
    /// rebase, or cherry-pick merge: merging one into `ref` would leave `ref`'s tree unchanged.
    ///
    /// A merge that conflicts or can't run counts as not merged, so on git older than 2.38, which has no
    /// `merge-tree --write-tree`, this returns no branches.
    public func mergedByRef(candidateRefs: [String], at path: String) throws -> [String: [String]] {
        var merged: [String: [String]] = [:]

        for ref in candidateRefs {
            merged[ref] = try branchNames(mergedInto: ref, at: path)
        }

        return merged
    }

    public func contentMergedByRef(mergedByRef: [String: [String]], localBranchNames: [String], at path: String) throws -> [String: [String]] {
        var contentMerged: [String: [String]] = [:]

        for (ref, mergedNames) in mergedByRef {
            let merged = Set(mergedNames)
            let unmerged = localBranchNames.filter { !merged.contains($0) }

            contentMerged[ref] = try contentMergedBranches(unmerged, into: ref, at: path)
        }

        return contentMerged
    }

    public func contentMergedBranches(_ branches: [String], into ref: String, at path: String) throws -> [String] {
        let treeResult = try runner.runGit(.revParseTree(ref: ref), at: path)
        let refTree = trimmed(treeResult.output)

        guard treeResult.exitCode == 0, !refTree.isEmpty else {
            return []
        }

        return try branches.filter { branch in
            let result = try runner.runGit(.mergeTreeWriteTree(base: ref, branch: branch), at: path)

            return result.exitCode == 0 && lines(of: result.output).first == refTree
        }
    }
}

// MARK: - Private Helpers
private extension GitClient {
    static let remoteHeadSuffix = "/HEAD"
    static let upstreamFieldCount = 4
    static let goneTrack = "[gone]"
    static let localBranchFieldCount = 4
    static let goneTrackWithoutBrackets = "gone"
    static let aheadPrefix = "ahead "
    static let behindPrefix = "behind "

    func localBranch(from line: String) -> LocalBranch? {
        let fields = line.split(separator: "\0", omittingEmptySubsequences: false).map(String.init)

        guard fields.count == Self.localBranchFieldCount, !fields[0].isEmpty else {
            return nil
        }

        let track = fields[3]

        return .init(
            name: fields[0],
            worktreePath: fields[1].isEmpty ? nil : fields[1],
            upstreamName: fields[2].isEmpty ? nil : fields[2],
            upstreamGone: track == Self.goneTrackWithoutBrackets,
            ahead: trackCount(in: track, prefix: Self.aheadPrefix),
            behind: trackCount(in: track, prefix: Self.behindPrefix)
        )
    }

    /// Reads one count from a track string such as `ahead 2, behind 1`.
    func trackCount(in track: String, prefix: String) -> Int {
        let part = track.components(separatedBy: ", ").first(where: { $0.hasPrefix(prefix) })

        return part.flatMap({ Int($0.dropFirst(prefix.count)) }) ?? 0
    }
}
