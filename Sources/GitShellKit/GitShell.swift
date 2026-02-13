//
//  GitShell.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import Foundation
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
    
    /// Runs a command where the output is not needed.
    ///
    /// - Parameter command: The command string to execute.
    /// - Throws: An error if the command fails.
    func runAndPrint(_ command: String) throws
}


// MARK: - Helper Methods
public extension GitShell {
    /// Retrieves the GitHub URL of the remote origin.
    ///
    /// - Parameter path: The path to the local repository.
    /// - Returns: The GitHub URL of the repository.
    /// - Throws: An error if the command fails.
    func getGitHubURL(at path: String?) throws -> String {
        return try runWithOutputWrappingFailure(makeGitCommand(.getRemoteURL, path: path)).toGitHubURL()
    }

    /// Checks whether a local Git repository exists at the specified path.
    ///
    /// - Parameter path: The path to check.
    /// - Returns: `true` if a Git repository exists, `false` otherwise.
    /// - Throws: An error if the command fails.
    func localGitExists(at path: String?) throws -> Bool {
        let output = try runWithOutputWrappingFailure(makeGitCommand(.localGitCheck, path: path))
        return GitShellOutput.isTrue(output)
    }

    /// Checks whether a remote origin exists for the repository.
    ///
    /// - Parameter path: The path to the local repository.
    /// - Returns: `true` if the remote exists, `false` otherwise.
    /// - Throws: An error if the command fails.
    func remoteExists(path: String?) throws -> Bool {
        let output = try runWithOutputWrappingFailure(makeGitCommand(.checkForRemote, path: path))
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
        return try runWithOutputWrappingFailure(makeGitCommand(command, path: path))
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
            let exists = GitShellOutput.isTrue(try runWithOutputWrappingFailure(localGitCommand))
            guard exists else { throw GitShellError.missingLocalGit }
        }
        
        let remoteCommand = makeGitCommand(.checkForRemote, path: path)
        commands.append(remoteCommand)
        let remoteOutput: String
        if mode == .execute {
            remoteOutput = try runWithOutputWrappingFailure(remoteCommand)
        } else {
            remoteOutput = ""
        }
        let hasRemote = GitShellOutput.containsOriginRemote(remoteOutput)
        
        if hasRemote {
            let remoteDefaultCommand = makeGitCommand(.getRemoteDefaultBranch, path: path)
            commands.append(remoteDefaultCommand)
            
            if mode == .execute {
                if let remoteDefault = GitShellOutput.parseRemoteDefaultBranch(try runWithOutputWrappingFailure(remoteDefaultCommand)) {
                    return remoteDefault
                }
            }
        }
        
        let defaultBranchCommand = makeGitCommand(.getInitDefaultBranch, path: path)
        commands.append(defaultBranchCommand)
        
        if mode == .execute {
            let configBranch = try runWithOutputWrappingFailure(defaultBranchCommand)
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
        
        let remoteOutput = try runWithOutputWrappingFailure(makeGitCommand(.checkForRemote, path: path))
        let remotes = GitShellOutput.parseRemotes(remoteOutput)
        let hasRemote = GitShellOutput.containsOriginRemote(remoteOutput)
        
        let currentBranch = try runWithOutputWrappingFailure(makeGitCommand(.getCurrentBranchName, path: path))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return .init(hasLocalGit: hasLocalGit, hasRemote: hasRemote, currentBranch: currentBranch, remotes: remotes)
    }
    
    /// Lists the names of all local branches.
    ///
    /// - Parameter path: An optional path to the repository.
    /// - Returns: An array of local branch names.
    /// - Throws: An error if the underlying Git command fails.
    func listLocalBranchNames(path: String? = nil) throws -> [String] {
        let output = try runWithOutputWrappingFailure(makeGitCommand(.listLocalBranches, path: path))
        return GitShellOutput.parseBranchList(output)
    }

    /// Lists the names of all remote branches, with the `origin/` prefix stripped.
    ///
    /// - Parameter path: An optional path to the repository.
    /// - Returns: An array of remote branch names.
    /// - Throws: An error if the underlying Git command fails.
    func listRemoteBranchNames(path: String? = nil) throws -> [String] {
        let output = try runWithOutputWrappingFailure(makeGitCommand(.listRemoteBranches, path: path))
        return GitShellOutput.parseRemoteBranchList(output)
    }

    /// Retrieves the list of local changes as porcelain status lines.
    ///
    /// - Parameter path: An optional path to the repository.
    /// - Returns: An array of change description strings.
    /// - Throws: An error if the underlying Git command fails.
    func getLocalChanges(path: String? = nil) throws -> [String] {
        let output = try runWithOutputWrappingFailure(makeGitCommand(.getLocalChanges, path: path))
        return GitShellOutput.parseLocalChanges(output)
    }

    /// Retrieves the creation date of the specified branch.
    ///
    /// - Parameters:
    ///   - name: The branch name.
    ///   - path: An optional path to the repository.
    /// - Returns: The creation date, or `nil` if parsing fails.
    /// - Throws: An error if the underlying Git command fails.
    func getBranchCreationDate(name: String, path: String? = nil) throws -> Date? {
        let output = try runWithOutputWrappingFailure(makeGitCommand(.getBranchCreationDate(branchName: name), path: path))
        return GitShellOutput.parseBranchCreationDate(output)
    }

    /// Retrieves the synchronization status between a local and remote branch.
    ///
    /// - Parameters:
    ///   - local: The local branch name.
    ///   - remote: The remote branch name (e.g., `"origin/main"`).
    ///   - path: An optional path to the repository.
    /// - Returns: A `BranchSyncStatus` describing the relationship between the branches.
    /// - Throws: An error if the underlying Git command fails.
    func getSyncStatus(local: String, remote: String, path: String? = nil) throws -> BranchSyncStatus {
        let output = try runWithOutputWrappingFailure(makeGitCommand(.compareBranchAndRemote(local: local, remote: remote), path: path))
        return GitShellOutput.parseSyncStatus(output)
    }

    /// Validates that the GitHub CLI is available and authenticated.
    ///
    /// - Parameter path: An optional path to use for command execution context.
    /// - Throws: `GitShellError.githubCLINotAvailable` or `GitShellError.githubCLINotAuthenticated`.
    func validateGitHubCLI(path: String? = nil) throws {
        do {
            try runAndPrint(makeGitHubCommand(.version, path: path))
        } catch {
            throw GitShellError.githubCLINotAvailable
        }

        do {
            try runAndPrint(makeGitHubCommand(.authStatus, path: path))
        } catch {
            throw GitShellError.githubCLINotAuthenticated
        }
    }

    /// Retrieves recent commits as structured `CommitInfo` values.
    ///
    /// - Parameters:
    ///   - count: The maximum number of commits to retrieve. Defaults to 10.
    ///   - path: An optional path to the repository.
    /// - Returns: An array of `CommitInfo` values.
    /// - Throws: An error if the underlying Git command fails.
    func getRecentCommits(count: Int = 10, path: String? = nil) throws -> [CommitInfo] {
        let output = try runWithOutputWrappingFailure(makeGitCommand(.log(count: count, format: GitShellOutput.commitLogFormat), path: path))
        return GitShellOutput.parseCommitLog(output)
    }

    /// Runs a command and wraps failures with contextual details.
    func runWithOutputWrappingFailure(_ command: String) throws -> String {
        do {
            return try runWithOutput(command)
        } catch {
            if let failure = error as? GitCommandFailure {
                throw failure
            }
            
            let nsError = error as NSError
            let output = (nsError.userInfo[NSLocalizedFailureReasonErrorKey] as? String ?? nsError.localizedDescription)
            throw GitCommandFailure(command: command, output: output)
        }
    }
    
    /// Runs a command without needing to capture output.
    func runAndPrint(_ command: String) throws {
        _ = try runWithOutputWrappingFailure(command)
    }
}
