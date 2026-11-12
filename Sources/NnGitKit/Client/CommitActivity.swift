public struct CommitActivity: Sendable, Equatable {
    public let shortSha: String
    public let day: String
    public let files: [FileChange]

    public init(shortSha: String, day: String, files: [FileChange]) {
        self.shortSha = shortSha
        self.day = day
        self.files = files
    }
}
