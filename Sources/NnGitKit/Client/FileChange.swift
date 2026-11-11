public struct FileChange: Sendable, Equatable {
    public let path: String
    public let added: Int?
    public let deleted: Int?

    public init(path: String, added: Int?, deleted: Int?) {
        self.path = path
        self.added = added
        self.deleted = deleted
    }
}
