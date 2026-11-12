public enum DefaultBranchRefDetector {
    public static func detect(defaultBranch: String, remoteBranchNames: [String]) -> String? {
        let candidates = remoteBranchNames.filter { RemoteBranchRef.branchName(of: $0) == defaultBranch }
        let conventionalRef = "\(DefaultBranchConventions.remote)/\(defaultBranch)"

        if candidates.contains(conventionalRef) {
            return conventionalRef
        }

        return candidates.sorted().first
    }
}
