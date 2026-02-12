//
//  RepoVisibility.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 12/16/25.
//

public enum RepoVisibility: String, CaseIterable, Sendable {
    /// The repository is publicly accessible.
    case publicRepo = "public"
    /// The repository is private and restricted.
    case privateRepo = "private"
}
