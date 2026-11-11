public struct UncommittedFile: Sendable, Equatable {
    public let path: String
    public let originalPath: String?
    public let hasStagedChanges: Bool
    public let hasUnstagedChanges: Bool
    public let untracked: Bool
    public let conflicted: Bool
    public let existsInHead: Bool
    public let change: Change

    public init(
        path: String,
        originalPath: String?,
        hasStagedChanges: Bool,
        hasUnstagedChanges: Bool,
        untracked: Bool,
        conflicted: Bool,
        existsInHead: Bool,
        change: Change
    ) {
        self.path = path
        self.originalPath = originalPath
        self.hasStagedChanges = hasStagedChanges
        self.hasUnstagedChanges = hasUnstagedChanges
        self.untracked = untracked
        self.conflicted = conflicted
        self.existsInHead = existsInHead
        self.change = change
    }
}

// MARK: - Dependencies
extension UncommittedFile {
    public enum Change: Sendable, Equatable {
        case added
        case modified
        case deleted
    }
}
