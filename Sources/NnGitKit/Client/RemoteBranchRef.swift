public enum RemoteBranchRef {
    public static func branchName(of remoteBranch: String) -> String? {
        guard let slash = remoteBranch.firstIndex(of: "/") else {
            return nil
        }

        return String(remoteBranch[remoteBranch.index(after: slash)...])
    }
}
