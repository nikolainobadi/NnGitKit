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
    private let infoProvider: RepoInfoProvider

    /// Initializes a `GitHubRepoStarter` with the given path, shell, and info provider.
    ///
    /// - Parameters:
    ///   - path: The file system path where the repository should be initialized.
    ///   - shell: The shell implementation for running Git commands.
    ///   - infoProvider: An object that provides repository information.
    public init(path: String?, shell: GitShell, infoProvider: RepoInfoProvider) {
        self.path = path
        self.shell = shell
        self.infoProvider = infoProvider
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
            if try !infoProvider.canUploadFromNonMainBranch() {
                throw GitShellError.currentBranchIsNotMainBranch
            }
        }

        let name = try infoProvider.getProjectName()
        let visibility = try infoProvider.getVisibility()
        let details = try infoProvider.getProjectDetails()

        try shell.runWithOutput(
            makeGitHubCommand(.createRemoteRepo(name: name, visibility: visibility.rawValue, details: details), path: path)
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

/// A protocol that provides necessary information for creating and managing a GitHub repository.
public protocol RepoInfoProvider {
    /// Retrieves the project name.
    func getProjectName() throws -> String

    /// Retrieves the project details or description.
    func getProjectDetails() throws -> String

    /// Retrieves the visibility of the repository.
    func getVisibility() throws -> RepoVisibility

    /// Determines whether uploading from a non-main branch is allowed.
    func canUploadFromNonMainBranch() throws -> Bool
}

