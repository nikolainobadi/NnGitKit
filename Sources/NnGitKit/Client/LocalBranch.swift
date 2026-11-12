public struct LocalBranch: Sendable, Equatable {
    public let name: String
    /// The worktree that has this branch checked out, including the main checkout.
    public let worktreePath: String?
    public let upstreamName: String?
    public let upstreamGone: Bool
    public let ahead: Int
    public let behind: Int

    public init(name: String, worktreePath: String?, upstreamName: String?, upstreamGone: Bool, ahead: Int, behind: Int) {
        self.name = name
        self.worktreePath = worktreePath
        self.upstreamName = upstreamName
        self.upstreamGone = upstreamGone
        self.ahead = ahead
        self.behind = behind
    }
}
