//
//  CommitInfo.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 2/12/26.
//

/// A structured representation of a Git commit.
public struct CommitInfo: Sendable, Equatable {
    public let hash: String
    public let message: String
    public let authorName: String
    public let authorEmail: String
    public let relativeDate: String

    public init(hash: String, message: String, authorName: String, authorEmail: String, relativeDate: String) {
        self.hash = hash
        self.message = message
        self.authorName = authorName
        self.authorEmail = authorEmail
        self.relativeDate = relativeDate
    }
}
