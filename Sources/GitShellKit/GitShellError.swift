//
//  GitShellError.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import Foundation

/// Errors that may occur during Git operations.
public enum GitShellError: Error {
    /// Indicates that a local Git repository was not found.
    case missingLocalGit
    /// Indicates that a local Git repository already exists.
    case localGitAlreadyExists
    /// Indicates that a remote GitHub repository already exists.
    case remoteRepoAlreadyExists
    /// Indicates that the current branch is not the main branch.
    case currentBranchIsNotMainBranch
    /// Indicates that the GitHub CLI is not installed or not available on PATH.
    case githubCLINotAvailable
    /// Indicates that the GitHub CLI is not authenticated.
    case githubCLINotAuthenticated
    /// Indicates that the remote repository was created but a subsequent step failed.
    case remoteCreatedFollowupFailed
}


// MARK: - LocalizedError
extension GitShellError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingLocalGit:
            return "No local Git repository found."
        case .localGitAlreadyExists:
            return "A local Git repository already exists."
        case .remoteRepoAlreadyExists:
            return "A remote GitHub repository already exists."
        case .currentBranchIsNotMainBranch:
            return "The current branch is not the default branch."
        case .githubCLINotAvailable:
            return "The GitHub CLI (gh) is not installed or not available on PATH."
        case .githubCLINotAuthenticated:
            return "The GitHub CLI is not authenticated. Run 'gh auth login' first."
        case .remoteCreatedFollowupFailed:
            return "The remote repository was created, but a subsequent step failed."
        }
    }
}
