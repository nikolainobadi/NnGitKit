public enum DefaultRefCandidatesBuilder {
    public static func make(localBranchNames: [String], remoteBranchNames: [String], remoteHeadBranches: [String: String], configuredDefaultBranch: String?) -> [String] {
        let candidateNames = Set(remoteHeadBranches.values.compactMap(RemoteBranchRef.branchName(of:)) + [configuredDefaultBranch].compactMap { $0 } + DefaultBranchConventions.branchNames)
        let remoteRefs = remoteBranchNames.filter { ref in
            guard let name = RemoteBranchRef.branchName(of: ref), name != DefaultBranchConventions.remoteHeadName else {
                return false
            }

            return candidateNames.contains(name)
        }

        return remoteRefs + localBranchNames.filter(candidateNames.contains)
    }
}
