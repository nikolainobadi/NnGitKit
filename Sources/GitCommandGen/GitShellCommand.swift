//
//  GitShellCommand.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 3/20/25.
//

/// Represents Git shell commands that can be executed using the Git CLI.
public enum GitShellCommand {
    // MARK: - Git Init
    
    /// Initializes a new Git repository.
    case gitInit
    
    /// Adds all changes to the staging area.
    case addAll
    
    /// Commits changes with the specified message.
    ///
    /// - Parameter message: The commit message.
    case commit(message: String)
    
    // MARK: - Repository

    /// Retrieves a Git configuration value by key.
    ///
    /// - Parameter key: The configuration key to look up.
    case getConfig(key: String)

    /// Pulls changes from the remote, optionally using rebase.
    case pull(withRebase: Bool)
    
    /// Pushes local changes to the remote repository.
    case push
    
    /// Fetches updates from the origin remote.
    case fetchOrigin
    
    /// Prunes stale branches from the origin remote.
    case pruneOrigin
    
    /// Retrieves the URL of the remote origin.
    case getRemoteURL
    
    /// Checks whether a Git repository exists locally.
    case localGitCheck
    
    /// Clones a repository from the specified URL.
    ///
    /// - Parameter url: The URL of the repository to clone.
    case clone(url: String)
    
    /// Rebases the current branch onto the specified branch.
    ///
    /// - Parameter branch: The branch to rebase onto.
    case rebase(onto: String)
    
    /// Checks for the presence of a remote origin.
    case checkForRemote
    
    /// Pushes a new remote branch to the origin.
    ///
    /// - Parameter branchName: The name of the branch to push.
    case pushNewRemote(branchName: String)
    
    /// Adds a GitHub remote with the specified username and project name.
    ///
    /// - Parameters:
    ///   - username: The GitHub username.
    ///   - projectName: The name of the repository.
    case addGitHubRemote(username: String, projectName: String)
    
    // MARK: - Branches

    /// Creates a new local branch that tracks a remote branch.
    ///
    /// - Parameters:
    ///   - local: The name of the local branch to create.
    ///   - remote: The name of the remote branch to track.
    case checkoutTracking(local: String, remote: String)

    /// Creates a new branch with the specified name.
    ///
    /// - Parameter name: The name of the new branch.
    case newBranch(branchName: String)
    
    /// Lists all local branches.
    case listLocalBranches
    
    /// Lists all branches that have been merged into the main branch.
    case listMergedBranches(branchName: String)
    
    /// Lists all remote branches.
    case listRemoteBranches
    
    /// Retrieves the name of the current branch.
    case getCurrentBranchName
    
    /// Switches to the specified branch.
    ///
    /// - Parameter name: The name of the branch to switch to.
    case switchBranch(branchName: String)
    
    /// Retrieves the creation date of the specified branch.
    ///
    /// - Parameter branch: The name of the branch.
    case getBranchCreationDate(branchName: String)
    
    /// Retrieves the default branch from the origin remote.
    case getRemoteDefaultBranch
    
    /// Retrieves the configured default branch for new repos.
    case getInitDefaultBranch
    
    /// Deletes the specified branch.
    ///
    /// - Parameters:
    ///   - name: The name of the branch to delete.
    ///   - forced: Whether to force delete the branch.
    case deleteBranch(name: String, forced: Bool)
    
    /// Compares the local and remote versions of the specified branches.
    ///
    /// - Parameters:
    ///   - local: The name of the local branch.
    ///   - remote: The name of the remote branch.
    case compareBranchAndRemote(local: String, remote: String)
    
    // MARK: - File Tracking

    /// Retrieves a list of local changes.
    case getLocalChanges

    /// Lists all tracked files in the repository.
    case listTrackedFiles

    /// Removes a file from the index without deleting it from disk.
    ///
    /// - Parameter path: The path of the file to untrack.
    case untrackFile(path: String)

    /// Clears all staged changes.
    case clearStagedFiles

    /// Clears all unstaged changes.
    case clearUnstagedFiles

    // MARK: - Reset

    /// Performs a soft reset, moving HEAD back by the specified number of commits.
    ///
    /// - Parameter count: The number of commits to reset.
    case softReset(count: Int)

    /// Performs a hard reset, discarding changes and moving HEAD back.
    ///
    /// - Parameter count: The number of commits to reset.
    case hardReset(count: Int)

    // MARK: - History

    /// Retrieves commit log entries in a specified format.
    ///
    /// - Parameters:
    ///   - count: The number of commits to retrieve.
    ///   - format: The pretty-print format string.
    case log(count: Int, format: String)
}

// MARK: - Arg String
extension GitShellCommand {
    /// The shell argument string corresponding to the Git shell command.
    var arg: String {
        switch self {
        // Git Init
        case .gitInit:
            return "init"
        case .addAll:
            return "add ."
        case .commit(let message):
            return "commit -m \"\(message)\""
            
        // Repository
        case .getConfig(let key):
            return "config --get \(key)"
        case .pull(let withRebase):
            return "pull\(withRebase ? " --rebase" : "")"
        case .push:
            return "push"
        case .fetchOrigin:
            return "fetch origin"
        case .pruneOrigin:
            return "remote prune origin"
        case .getRemoteURL:
            return "remote get-url origin"
        case .localGitCheck:
            return "rev-parse --is-inside-work-tree"
        case .clone(let url):
            return "clone \(url)"
        case .rebase(let branch):
            return "rebase \(branch)"
        case .checkForRemote:
            return "remote"
        case .pushNewRemote(let branchName):
            return "push -u origin \(branchName)"
        case .addGitHubRemote(let username, let projectName):
            return "remote add origin https://github.com/\(username)/\(projectName).git"
        case .getRemoteDefaultBranch:
            return "symbolic-ref refs/remotes/origin/HEAD"
        case .getInitDefaultBranch:
            return "config --get init.defaultBranch"
            
        // Branches
        case .checkoutTracking(let local, let remote):
            return "checkout -b \(local) \(remote)"
        case .newBranch(let name):
            return "checkout -b \(name)"
        case .listLocalBranches:
            return "branch --list"
        case .listMergedBranches(let branchName):
            return "branch --merged \(branchName)"
        case .listRemoteBranches:
            return "branch -r"
        case .switchBranch(let name):
            return "checkout \(name)"
        case .getBranchCreationDate(let branch):
            return "log --reverse --pretty=format:\"%ad\" --date=iso-local \(branch) | head -1"
        case .deleteBranch(let name, let forced):
            return "branch -\(forced ? "D" : "d") \(name)"
        case .getCurrentBranchName:
            return "rev-parse --abbrev-ref HEAD"
        case .compareBranchAndRemote(let local, let remote):
            return "rev-list --left-right --count \(local)...\(remote)"
        
        // File Tracking
        case .getLocalChanges:
            return "status --porcelain"
        case .listTrackedFiles:
            return "ls-files"
        case .untrackFile(let path):
            return "rm --cached \(path)"
        case .clearStagedFiles:
            return "reset --hard HEAD"
        case .clearUnstagedFiles:
            return "clean -fd"

        // Reset
        case .softReset(let count):
            return "reset --soft HEAD~\(count)"
        case .hardReset(let count):
            return "reset --hard HEAD~\(count)"

        // History
        case .log(let count, let format):
            return "log -n \(count) --pretty=format:\"\(format)\""
        }
    }
}
