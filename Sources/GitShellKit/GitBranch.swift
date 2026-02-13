//
//  GitBranch.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 2/12/26.
//

import Foundation

/// A rich model representing a local Git branch with metadata.
public struct GitBranch: Sendable, Equatable {
    public let name: String
    public let isMerged: Bool
    public let isCurrentBranch: Bool
    public let creationDate: Date?
    public let syncStatus: BranchSyncStatus

    public init(
        name: String,
        isMerged: Bool,
        isCurrentBranch: Bool,
        creationDate: Date?,
        syncStatus: BranchSyncStatus
    ) {
        self.name = name
        self.isMerged = isMerged
        self.isCurrentBranch = isCurrentBranch
        self.creationDate = creationDate
        self.syncStatus = syncStatus
    }
}
