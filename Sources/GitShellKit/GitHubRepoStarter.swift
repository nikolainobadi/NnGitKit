//
//  GitHubRepoStarter.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import Foundation
import GitCommandGen

/// A utility for creating and managing GitHub repositories.
public struct GitHubRepoStarter {
    private let path: String?
    private let shell: GitShell
    private let repoInfo: RepoInfo

    /// Initializes a `GitHubRepoStarter` with the given path, shell, and repoInfo.
    ///
    /// - Parameters:
    ///   - path: The file system path where the repository should be initialized.
    ///   - shell: The shell implementation for running Git commands.
    ///   - repoInfo: An object that provides repository information.
    public init(path: String?, shell: GitShell, repoInfo: RepoInfo) {
        self.path = path
        self.shell = shell
        self.repoInfo = repoInfo
    }
}

// MARK: - Actions
public extension GitHubRepoStarter {
    typealias GitHubURL = String

    /// Initializes a new GitHub repository and returns its URL.
    ///
    /// - Returns: The GitHub URL of the newly created repository.
    /// - Throws: An error if the repository cannot be created or initialized.
    @discardableResult
    func repoInit() throws -> GitHubURL {
        guard try shell.localGitExists(at: path) else {
            throw GitShellError.missingLocalGit
        }

        if try shell.remoteExists(path: path) {
            throw GitShellError.remoteRepoAlreadyExists
        }

        let currentBranchName = try shell.runWithOutput(makeGitCommand(.getCurrentBranchName, path: path))

        if currentBranchName != "main" {
            if !repoInfo.canUploadFromNonMainBranch {
                throw GitShellError.currentBranchIsNotMainBranch
            }
        }

        try shell.runWithOutput(
            makeGitHubCommand(.createRemoteRepo(name: repoInfo.name, visibility: repoInfo.visibility.rawValue, details: repoInfo.details), path: path)
        )

        return try shell.getGitHubURL(at: path)
    }
}


// MARK: - Dependencies
/// Represents the visibility options for a GitHub repository.
public enum RepoVisibility: String, CaseIterable, Sendable {
    /// The repository is publicly accessible.
    case publicRepo = "public"
    /// The repository is private and restricted.
    case privateRepo = "private"
}

public struct RepoInfo {
    public let name: String
    public let details: String
    public let visibility: RepoVisibility
    public let canUploadFromNonMainBranch: Bool
    
    public init(name: String, details: String, visibility: RepoVisibility, canUploadFromNonMainBranch: Bool) {
        self.name = name
        self.details = details
        self.visibility = visibility
        self.canUploadFromNonMainBranch = canUploadFromNonMainBranch
    }
}
