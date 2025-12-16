//
//  RepoInfo.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 12/16/25.
//

public struct RepoInfo {
    public let name: String
    public let details: String
    public let visibility: RepoVisibility
    public let branchPolicy: BranchPolicy
    public let defaultBranch: String
    
    public init(name: String, details: String, visibility: RepoVisibility, branchPolicy: BranchPolicy, defaultBranch: String = "main") {
        self.name = name
        self.details = details
        self.visibility = visibility
        self.branchPolicy = branchPolicy
        self.defaultBranch = defaultBranch
    }
}
