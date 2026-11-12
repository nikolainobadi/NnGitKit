public struct Worktree: Sendable, Equatable {
    public let path: String
    /// The checked-out branch without `refs/heads/`, or `nil` when the worktree is detached or bare.
    public let branch: String?
    /// The main checkout, which git always lists first.
    public let primary: Bool
    public let detached: Bool
    public let locked: Bool
    public let lockReason: String?
    /// The worktree's directory is gone, so `git worktree prune` would remove its record.
    public let prunable: Bool

    public init(path: String, branch: String?, primary: Bool, detached: Bool, locked: Bool, lockReason: String?, prunable: Bool) {
        self.path = path
        self.branch = branch
        self.primary = primary
        self.detached = detached
        self.locked = locked
        self.lockReason = lockReason
        self.prunable = prunable
    }
}
