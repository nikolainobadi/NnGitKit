/// How hard `git worktree remove` pushes past the checks that protect a worktree.
public enum WorktreeRemovalForce: Equatable, Sendable {
    case none
    /// Removes a worktree that has uncommitted changes or untracked files.
    case discardChanges
    /// Removes a locked worktree, along with any changes in it.
    case overrideLock
}

// MARK: - Flags
extension WorktreeRemovalForce {
    var flags: [String] {
        switch self {
        case .none:
            return []
        case .discardChanges:
            return ["--force"]
        case .overrideLock:
            return ["--force", "--force"]
        }
    }
}
