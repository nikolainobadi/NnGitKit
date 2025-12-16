//
//  GitShell.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import GitCommandGen

/// A protocol defining a shell interface for running Git commands.
public protocol GitShell {
    /// Runs a command in the shell and returns the output.
    ///
    /// - Parameter command: The command string to execute.
    /// - Returns: The output from the shell.
    /// - Throws: An error if the command fails.
    @discardableResult
    func runWithOutput(_ command: String) throws -> String
}


// MARK: - Helper Methods
public extension GitShell {
    /// Retrieves the GitHub URL of the remote origin.
    ///
    /// - Parameter path: The path to the local repository.
    /// - Returns: The GitHub URL of the repository.
    /// - Throws: An error if the command fails.
    func getGitHubURL(at path: String?) throws -> String {
        return try runWithOutput(makeGitCommand(.getRemoteURL, path: path)).toGitHubURL()
    }

    /// Checks whether a local Git repository exists at the specified path.
    ///
    /// - Parameter path: The path to check.
    /// - Returns: `true` if a Git repository exists, `false` otherwise.
    /// - Throws: An error if the command fails.
    func localGitExists(at path: String?) throws -> Bool {
        let output = try runWithOutput(makeGitCommand(.localGitCheck, path: path))
        return GitShellOutput.isTrue(output)
    }

    /// Checks whether a remote origin exists for the repository.
    ///
    /// - Parameter path: The path to the local repository.
    /// - Returns: `true` if the remote exists, `false` otherwise.
    /// - Throws: An error if the command fails.
    func remoteExists(path: String?) throws -> Bool {
        let output = try runWithOutput(makeGitCommand(.checkForRemote, path: path))
        return GitShellOutput.containsOriginRemote(output)
    }
    
    /// Runs a Git command and returns the resulting output string.
    ///
    /// - Parameters:
    ///   - command: The `GitShellCommand` to execute.
    ///   - path: The optional path to the Git repository where the command should be run.
    /// - Returns: The output from the Git command as a string.
    /// - Throws: An error if the command execution fails.
    @discardableResult
    func runGitCommandWithOutput(_ command: GitShellCommand, path: String?) throws -> String {
        return try runWithOutput(makeGitCommand(command, path: path))
    }
    
    /// Resolves the default branch, preferring the origin remote when available.
    ///
    /// - Parameter path: The path to the repository.
    /// - Returns: The resolved default branch name.
    /// - Throws: `GitShellError.missingLocalGit` if the directory is not a Git repository.
    func getDefaultBranch(at path: String?) throws -> String {
        var commands: [String] = []
        return try getDefaultBranch(at: path, mode: .execute, commands: &commands)
    }
    
    /// Resolves the default branch using the provided execution mode, recording commands.
    ///
    /// - Parameters:
    ///   - path: The path to the repository.
    ///   - mode: Whether to execute or only plan commands.
    ///   - commands: A log of the commands that were executed or planned.
    /// - Returns: The resolved default branch name.
    /// - Throws: `GitShellError.missingLocalGit` if the directory is not a Git repository.
    func getDefaultBranch(at path: String?, mode: ExecutionMode, commands: inout [String]) throws -> String {
        let localGitCommand = makeGitCommand(.localGitCheck, path: path)
        commands.append(localGitCommand)
        if mode == .execute {
            let exists = GitShellOutput.isTrue(try runWithOutput(localGitCommand))
            guard exists else { throw GitShellError.missingLocalGit }
        }
        
        let remoteCommand = makeGitCommand(.checkForRemote, path: path)
        commands.append(remoteCommand)
        let remoteOutput: String
        if mode == .execute {
            remoteOutput = try runWithOutput(remoteCommand)
        } else {
            remoteOutput = ""
        }
        let hasRemote = GitShellOutput.containsOriginRemote(remoteOutput)
        
        if hasRemote {
            let remoteDefaultCommand = makeGitCommand(.getRemoteDefaultBranch, path: path)
            commands.append(remoteDefaultCommand)
            
            if mode == .execute {
                if let remoteDefault = GitShellOutput.parseRemoteDefaultBranch(try runWithOutput(remoteDefaultCommand)) {
                    return remoteDefault
                }
            }
        }
        
        let defaultBranchCommand = makeGitCommand(.getInitDefaultBranch, path: path)
        commands.append(defaultBranchCommand)
        
        if mode == .execute {
            let configBranch = try runWithOutput(defaultBranchCommand)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !configBranch.isEmpty {
                return configBranch
            }
        }
        
        return "main"
    }
    
    /// Inspects repository state in a read-only manner.
    ///
    /// - Parameter path: The path to the repository.
    /// - Returns: A `RepoState` snapshot with basic repo details.
    func inspectRepoState(at path: String?) throws -> RepoState {
        let hasLocalGit: Bool
        
        do {
            hasLocalGit = try localGitExists(at: path)
        } catch {
            hasLocalGit = false
        }
        
        guard hasLocalGit else {
            return RepoState(hasLocalGit: false, hasRemote: false, currentBranch: "", remotes: [])
        }
        
        let remoteOutput = try runWithOutput(makeGitCommand(.checkForRemote, path: path))
        let remotes = GitShellOutput.parseRemotes(remoteOutput)
        let hasRemote = GitShellOutput.containsOriginRemote(remoteOutput)
        
        let currentBranch = try runWithOutput(makeGitCommand(.getCurrentBranchName, path: path))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return .init(hasLocalGit: hasLocalGit, hasRemote: hasRemote, currentBranch: currentBranch, remotes: remotes)
    }
}


// MARK: - Extension Dependencies
public extension String {
    /// Converts a Git SSH URL to an HTTPS URL.
    ///
    /// - Returns: A formatted HTTPS URL for the GitHub repository.
    func toGitHubURL() -> String {
        return GitShellOutput.normalizeGitHubURL(self)
    }
}
