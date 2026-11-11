public struct BranchUpstream: Sendable, Equatable {
    public let name: String
    public let remote: String
    public let mergeRef: String
    public let remoteBranchIsGone: Bool

    public init(name: String, remote: String, mergeRef: String, remoteBranchIsGone: Bool) {
        self.name = name
        self.remote = remote
        self.mergeRef = mergeRef
        self.remoteBranchIsGone = remoteBranchIsGone
    }
}
