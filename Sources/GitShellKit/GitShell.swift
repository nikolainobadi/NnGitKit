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
        guard try localGitExists(at: path) else {
            throw GitShellError.missingLocalGit
        }
        
        if let remoteDefaultBranch = try remoteDefaultBranch(at: path) {
            return remoteDefaultBranch
        }
        
        if let configBranch = try? runWithOutput(makeGitCommand(.getInitDefaultBranch, path: path))
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !configBranch.isEmpty {
            return configBranch
        }
        
        return "main"
    }
    
    /// Attempts to read the origin default branch without throwing on failure.
    private func remoteDefaultBranch(at path: String?) throws -> String? {
        guard (try? remoteExists(path: path)) == true else { return nil }
        
        do {
            let output = try runWithOutput(makeGitCommand(.getRemoteDefaultBranch, path: path))
            return GitShellOutput.parseRemoteDefaultBranch(output)
        } catch {
            return nil
        }
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
