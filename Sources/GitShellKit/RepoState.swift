//
//  RepoState.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 2/8/25.
//

/// A read-only snapshot of repository state.
public struct RepoState: Sendable, Equatable {
    public let hasLocalGit: Bool
    public let hasRemote: Bool
    public let currentBranch: String
    public let remotes: [String]
    public let hasUncommittedChanges: Bool
    public let defaultBranch: String?
    public let syncStatus: BranchSyncStatus?
    public let trackedFileCount: Int

    public init(
        hasLocalGit: Bool,
        hasRemote: Bool,
        currentBranch: String,
        remotes: [String],
        hasUncommittedChanges: Bool = false,
        defaultBranch: String? = nil,
        syncStatus: BranchSyncStatus? = nil,
        trackedFileCount: Int = 0
    ) {
        self.hasLocalGit = hasLocalGit
        self.hasRemote = hasRemote
        self.currentBranch = currentBranch
        self.remotes = remotes
        self.hasUncommittedChanges = hasUncommittedChanges
        self.defaultBranch = defaultBranch
        self.syncStatus = syncStatus
        self.trackedFileCount = trackedFileCount
    }
}
