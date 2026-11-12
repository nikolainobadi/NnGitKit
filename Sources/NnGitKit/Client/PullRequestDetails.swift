public struct PullRequestDetails: Sendable, Equatable {
    public let headBranch: String
    public let pullRequestIsOpen: Bool
    public let headIsInFork: Bool

    public init(headBranch: String, pullRequestIsOpen: Bool, headIsInFork: Bool) {
        self.headBranch = headBranch
        self.pullRequestIsOpen = pullRequestIsOpen
        self.headIsInFork = headIsInFork
    }
}
