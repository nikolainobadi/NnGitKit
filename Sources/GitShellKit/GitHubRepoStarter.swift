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

// MARK: - Types
public extension GitHubRepoStarter {
    typealias GitHubURL = String
    
    /// Represents the validation state before initializing a GitHub repository.
    struct RepoInitValidation {
        public let currentBranchName: String
    }
}

// MARK: - Actions
public extension GitHubRepoStarter {
    /// Initializes a new GitHub repository and returns its URL.
    ///
    /// - Returns: The GitHub URL of the newly created repository.
    /// - Throws: An error if the repository cannot be created or initialized.
    @discardableResult
    func repoInit() throws -> GitHubURL {
        _ = try validateRepoInit()

        return try createRemoteRepoAndGetURL()
    }
    
    /// Validates that the repository is ready for initialization on GitHub.
    ///
    /// - Returns: The validation details including the current branch name.
    /// - Throws: `GitShellError` if validation fails.
    func validateRepoInit() throws -> RepoInitValidation {
        guard try shell.localGitExists(at: path) else {
            throw GitShellError.missingLocalGit
        }

        if try shell.remoteExists(path: path) {
            throw GitShellError.remoteRepoAlreadyExists
        }

        let currentBranchName = try shell
            .runWithOutput(makeGitCommand(.getCurrentBranchName, path: path))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if !repoInfo.branchPolicy.allowsUpload(from: currentBranchName) {
            throw GitShellError.currentBranchIsNotMainBranch
        }
        
        return RepoInitValidation(currentBranchName: currentBranchName)
    }
    
    /// Executes the side-effectful steps to create the GitHub remote and fetch its URL.
    ///
    /// - Returns: The GitHub URL for the newly created remote.
    /// - Throws: An error if any command fails.
    func createRemoteRepoAndGetURL() throws -> GitHubURL {
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

/// Branch upload policy for initializing the GitHub repository.
public enum BranchPolicy: Sendable {
    /// Only allow uploads from the main branch.
    case mainOnly
    /// Allow uploads from any branch (including non-main).
    case allowNonMain
    
    func allowsUpload(from branchName: String) -> Bool {
        switch self {
        case .mainOnly:
            return branchName == "main"
        case .allowNonMain:
            return true
        }
    }
}

public struct RepoInfo {
    public let name: String
    public let details: String
    public let visibility: RepoVisibility
    public let branchPolicy: BranchPolicy
    
    public init(name: String, details: String, visibility: RepoVisibility, branchPolicy: BranchPolicy) {
        self.name = name
        self.details = details
        self.visibility = visibility
        self.branchPolicy = branchPolicy
    }
}
