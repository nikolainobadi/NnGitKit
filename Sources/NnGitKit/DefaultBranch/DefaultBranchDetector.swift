public enum DefaultBranchDetector {
    public static func detect(remoteHeadBranches: [String: String], upstreamRemote: String?, configuredDefaultBranch: String?, localBranchNames: [String]) -> String? {
        if let remoteHeadBranch = preferredRemoteHeadBranch(remoteHeadBranches: remoteHeadBranches, upstreamRemote: upstreamRemote) {
            return RemoteBranchRef.branchName(of: remoteHeadBranch) ?? remoteHeadBranch
        }

        if let configuredDefaultBranch, !configuredDefaultBranch.isEmpty {
            return configuredDefaultBranch
        }

        return DefaultBranchConventions.branchNames.first(where: { localBranchNames.contains($0) })
    }
}

// MARK: - Private Methods
private extension DefaultBranchDetector {
    static func preferredRemoteHeadBranch(remoteHeadBranches: [String: String], upstreamRemote: String?) -> String? {
        if let upstreamRemote, let remoteHeadBranch = remoteHeadBranches[upstreamRemote] {
            return remoteHeadBranch
        }

        if let remoteHeadBranch = remoteHeadBranches[DefaultBranchConventions.remote] {
            return remoteHeadBranch
        }

        return remoteHeadBranches.keys.sorted().first.flatMap { remoteHeadBranches[$0] }
    }
}
