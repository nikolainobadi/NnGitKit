//
//  GitShellError.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 3/21/25.
//

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
}
