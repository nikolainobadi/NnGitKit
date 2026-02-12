//
//  BranchSyncStatus.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 2/12/26.
//

/// Describes the synchronization state between a local branch and its remote counterpart.
public enum BranchSyncStatus: Sendable, Equatable {
    /// The local branch is ahead of the remote by a number of commits.
    case ahead(Int)

    /// The local branch is behind the remote by a number of commits.
    case behind(Int)

    /// The local and remote branches are in sync.
    case nsync

    /// The branches have diverged with commits on both sides.
    case diverged(ahead: Int, behind: Int)

    /// No remote tracking branch exists.
    case noRemoteBranch

    /// The sync status could not be determined.
    case undetermined
}
