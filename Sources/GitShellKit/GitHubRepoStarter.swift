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
    
    /// The result of a repository initialization, including planned or executed commands.
    public struct RepoInitResult {
        public let url: GitHubURL?
        public let commands: [String]
        
        public init(url: GitHubURL?, commands: [String]) {
            self.url = url
            self.commands = commands
        }
    }

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
    /// Initializes a new GitHub repository and returns its URL.
    ///
    /// - Returns: The GitHub URL of the newly created repository.
    /// - Throws: An error if the repository cannot be created or initialized.
    @discardableResult
    func repoInit() throws -> GitHubURL {
        let result = try repoInit(mode: .execute)
        guard let url = result.url else {
            throw GitShellError.remoteCreatedFollowupFailed
        }
        return url
    }
    
    /// Initializes a new GitHub repository and returns the result along with planned commands.
    ///
    /// - Parameter mode: Whether to execute commands or only plan them.
    /// - Returns: The GitHub URL (when executed) and the commands in order.
    /// - Throws: An error if initialization fails in execute mode.
    @discardableResult
    func repoInit(mode: ExecutionMode) throws -> RepoInitResult {
        var commands: [String] = []
        _ = try validateRepoInit(mode: mode, commands: &commands)

        var remoteCreated = false
        
        do {
            let createCommand = makeGitHubCommand(.createRemoteRepo(name: repoInfo.name, visibility: repoInfo.visibility.rawValue, details: repoInfo.details), path: path)
            commands.append(createCommand)
            
            if mode == .execute {
                try shell.runWithOutput(createCommand)
                remoteCreated = true
            }
            
            let urlCommand = makeGitCommand(.getRemoteURL, path: path)
            commands.append(urlCommand)
            
            if mode == .execute {
                let url = try shell.getGitHubURL(at: path)
                return RepoInitResult(url: url, commands: commands)
            }
            
            return RepoInitResult(url: nil, commands: commands)
        } catch {
            if remoteCreated {
                throw GitShellError.remoteCreatedFollowupFailed
            }
            throw error
        }
    }
    
    /// Validates that the repository is ready for initialization on GitHub.
    ///
    /// - Returns: The validation details including the current branch name.
    /// - Throws: `GitShellError` if validation fails.
    func validateRepoInit() throws -> RepoInitValidation {
        var commands: [String] = []
        return try validateRepoInit(mode: .execute, commands: &commands)
    }
    
    /// Validates that the repository is ready for initialization on GitHub using the provided execution mode.
    ///
    /// - Parameters:
    ///   - mode: Whether to execute commands or only plan them.
    ///   - commands: A log of the commands that were executed or planned.
    /// - Returns: The validation details including the current branch name.
    /// - Throws: `GitShellError` if validation fails in execute mode.
    func validateRepoInit(mode: ExecutionMode, commands: inout [String]) throws -> RepoInitValidation {
        let versionCommand = makeGitHubCommand(.version, path: path)
        commands.append(versionCommand)
        if mode == .execute {
            do {
                _ = try shell.runWithOutput(versionCommand)
            } catch {
                throw GitShellError.githubCLINotAvailable
            }
        }
        
        let authCommand = makeGitHubCommand(.authStatus, path: path)
        commands.append(authCommand)
        if mode == .execute {
            do {
                _ = try shell.runWithOutput(authCommand)
            } catch {
                throw GitShellError.githubCLINotAuthenticated
            }
        }
        
        let localGitCommand = makeGitCommand(.localGitCheck, path: path)
        commands.append(localGitCommand)
        if mode == .execute {
            let hasLocalGit = GitShellOutput.isTrue(try shell.runWithOutput(localGitCommand))
            guard hasLocalGit else { throw GitShellError.missingLocalGit }
        }

        let remoteCommand = makeGitCommand(.checkForRemote, path: path)
        commands.append(remoteCommand)
        if mode == .execute {
            let remoteOutput = try shell.runWithOutput(remoteCommand)
            if GitShellOutput.containsOriginRemote(remoteOutput) {
                throw GitShellError.remoteRepoAlreadyExists
            }
        }

        let currentBranchCommand = makeGitCommand(.getCurrentBranchName, path: path)
        commands.append(currentBranchCommand)
        let currentBranchName: String
        if mode == .execute {
            currentBranchName = try shell
                .runWithOutput(currentBranchCommand)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            currentBranchName = repoInfo.defaultBranch
        }

        let defaultBranch = try shell.getDefaultBranch(at: path, mode: mode, commands: &commands)
        
        if mode == .execute && !repoInfo.branchPolicy.allowsUpload(from: currentBranchName, defaultBranch: defaultBranch) {
            throw GitShellError.currentBranchIsNotMainBranch
        }
        
        return RepoInitValidation(currentBranchName: currentBranchName)
    }
    
    /// Executes the side-effectful steps to create the GitHub remote and fetch its URL.
    ///
    /// - Returns: The GitHub URL for the newly created remote.
    /// - Throws: An error if any command fails.
    func createRemoteRepoAndGetURL() throws -> GitHubURL {
        var remoteCreated = false
        
        do {
            try shell.runWithOutput(
                makeGitHubCommand(.createRemoteRepo(name: repoInfo.name, visibility: repoInfo.visibility.rawValue, details: repoInfo.details), path: path)
            )
            remoteCreated = true
            
            return try shell.getGitHubURL(at: path)
        } catch {
            if remoteCreated {
                throw GitShellError.remoteCreatedFollowupFailed
            }
            throw error
        }
    }
    
    /// Ensures the GitHub CLI is available and authenticated before attempting remote creation.
    ///
    /// - Throws: `GitShellError.githubCLINotAvailable` or `GitShellError.githubCLINotAuthenticated`.
    func validateGitHubCLI() throws {
        do {
            _ = try shell.runWithOutput(makeGitHubCommand(.version, path: path))
        } catch {
            throw GitShellError.githubCLINotAvailable
        }
        
        do {
            _ = try shell.runWithOutput(makeGitHubCommand(.authStatus, path: path))
        } catch {
            throw GitShellError.githubCLINotAuthenticated
        }
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
