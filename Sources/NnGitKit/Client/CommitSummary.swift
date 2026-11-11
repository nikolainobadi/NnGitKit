public struct CommitSummary: Sendable, Equatable {
    public let sha: String
    public let shortSha: String
    public let subject: String
    public let authorName: String
    public let authorEmail: String
    public let relativeDate: String
    public let parentCount: Int

    public init(
        sha: String,
        shortSha: String,
        subject: String,
        authorName: String,
        authorEmail: String,
        relativeDate: String,
        parentCount: Int
    ) {
        self.sha = sha
        self.shortSha = shortSha
        self.subject = subject
        self.authorName = authorName
        self.authorEmail = authorEmail
        self.relativeDate = relativeDate
        self.parentCount = parentCount
    }
}
