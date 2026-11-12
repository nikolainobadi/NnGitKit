public struct UncommittedFileCounts: Sendable, Equatable {
    public let added: Int
    public let modified: Int
    public let deleted: Int

    public init(added: Int, modified: Int, deleted: Int) {
        self.added = added
        self.modified = modified
        self.deleted = deleted
    }
}

// MARK: - Clean
public extension UncommittedFileCounts {
    static let clean = UncommittedFileCounts(added: 0, modified: 0, deleted: 0)
}
