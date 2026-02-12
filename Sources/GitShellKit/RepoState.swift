//
//  RepoState.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 2/8/25.
//

/// A read-only snapshot of repository state.
public struct RepoState {
    public let hasLocalGit: Bool
    public let hasRemote: Bool
    public let currentBranch: String
    public let remotes: [String]
    
    public init(hasLocalGit: Bool, hasRemote: Bool, currentBranch: String, remotes: [String]) {
        self.hasLocalGit = hasLocalGit
        self.hasRemote = hasRemote
        self.currentBranch = currentBranch
        self.remotes = remotes
    }
}
