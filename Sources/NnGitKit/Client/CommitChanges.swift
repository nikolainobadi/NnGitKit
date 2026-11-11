public struct CommitChanges: Sendable, Equatable {
    public let shortSha: String
    public let date: String
    public let subject: String
    public let files: [FileChange]
    public let createdPaths: [String]
    public let deletedPaths: [String]

    public init(shortSha: String, date: String, subject: String, files: [FileChange], createdPaths: [String], deletedPaths: [String]) {
        self.shortSha = shortSha
        self.date = date
        self.subject = subject
        self.files = files
        self.createdPaths = createdPaths
        self.deletedPaths = deletedPaths
    }
}
