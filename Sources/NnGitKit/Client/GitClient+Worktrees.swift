// MARK: - Worktrees
extension GitClient {
    /// Every worktree of the repository, the main checkout first.
    public func worktrees(at path: String) throws -> [Worktree] {
        let fields = try runExpectingSuccess(.worktreeList, at: path).components(separatedBy: "\0")
        var worktrees: [Worktree] = []
        var record: [String] = []

        for field in fields + [""] {
            guard field.isEmpty else {
                record.append(field)
                continue
            }

            if let worktree = worktree(from: record, primary: worktrees.isEmpty) {
                worktrees.append(worktree)
            }

            record = []
        }

        return worktrees
    }

    public func removeWorktree(at worktreePath: String, force: WorktreeRemovalForce, in path: String) throws {
        try runExpectingSuccess(.worktreeRemove(path: worktreePath, force: force), at: path)
    }

    /// Creates a worktree on a new branch that starts at `base` and tracks nothing.
    public func addWorktree(at worktreePath: String, newBranch branch: String, from base: String, in path: String) throws {
        try runExpectingSuccess(.worktreeAddNewBranch(path: worktreePath, branch: branch, base: base), at: path)
    }

    /// Creates a worktree with an existing local branch checked out.
    public func addWorktree(at worktreePath: String, branch: String, in path: String) throws {
        try runExpectingSuccess(.worktreeAdd(path: worktreePath, branch: branch), at: path)
    }

    /// Creates a worktree on a new local branch that tracks `remoteBranch`.
    public func addWorktree(at worktreePath: String, trackingBranch branch: String, remoteBranch: String, in path: String) throws {
        try runExpectingSuccess(.worktreeAddTracking(path: worktreePath, branch: branch, remoteBranch: remoteBranch), at: path)
    }

    /// Removes the records of worktrees whose directories no longer exist.
    public func pruneWorktrees(at path: String) throws {
        try runExpectingSuccess(.worktreePrune, at: path)
    }
}

// MARK: - Private Helpers
private extension GitClient {
    static let worktreePrefix = "worktree "
    static let branchPrefix = "branch "
    static let branchRefPrefix = "refs/heads/"
    static let detachedField = "detached"
    static let lockedField = "locked"
    static let prunableField = "prunable"

    /// Builds a worktree from one porcelain record, whose fields are lines such as `worktree <path>`,
    /// `branch refs/heads/<name>`, `detached`, `locked [<reason>]`, and `prunable [<reason>]`.
    func worktree(from record: [String], primary: Bool) -> Worktree? {
        guard let pathField = record.first(where: { $0.hasPrefix(Self.worktreePrefix) }) else {
            return nil
        }

        let branchRef = record.first(where: { $0.hasPrefix(Self.branchPrefix) }).map({ String($0.dropFirst(Self.branchPrefix.count)) })
        let lockField = record.first(where: { $0 == Self.lockedField || $0.hasPrefix(Self.lockedField + " ") })
        let lockReason = lockField.map({ String($0.dropFirst(Self.lockedField.count)).trimmingCharacters(in: .whitespaces) })

        return .init(
            path: String(pathField.dropFirst(Self.worktreePrefix.count)),
            branch: branchRef.map({ $0.hasPrefix(Self.branchRefPrefix) ? String($0.dropFirst(Self.branchRefPrefix.count)) : $0 }),
            primary: primary,
            detached: record.contains(Self.detachedField),
            locked: lockField != nil,
            lockReason: lockReason.flatMap({ $0.isEmpty ? nil : $0 }),
            prunable: record.contains(where: { $0 == Self.prunableField || $0.hasPrefix(Self.prunableField + " ") })
        )
    }
}
