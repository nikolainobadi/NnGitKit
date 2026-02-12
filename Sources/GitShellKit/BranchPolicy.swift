//
//  BranchPolicy.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 12/16/25.
//

public enum BranchPolicy: Sendable {
    case mainOnly
    case allowNonMain
}



// MARK: - Helpers
extension BranchPolicy {
    func allowsUpload(from branchName: String, defaultBranch: String) -> Bool {
        switch self {
        case .mainOnly:
            return branchName == defaultBranch
        case .allowNonMain:
            return true
        }
    }
}
