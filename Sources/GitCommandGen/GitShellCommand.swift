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
    case commit(String)
    
    // MARK: - Repository
    
    /// Pulls changes from the remote repository.
    case pull
    
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
    case clone(String)
    
    /// Rebases the current branch onto the specified branch.
    ///
    /// - Parameter branch: The branch to rebase onto.
    case rebase(String)
    
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
    
    /// Creates a new branch with the specified name.
    ///
    /// - Parameter name: The name of the new branch.
    case newBranch(String)
    
    /// Lists all local branches.
    case listLocalBranches
    
    /// Lists all branches that have been merged into the main branch.
    case listMergedBranches
    
    /// Lists all remote branches.
    case listRemoteBranches
    
    /// Retrieves the name of the current branch.
    case getCurrentBranchName
    
    /// Switches to the specified branch.
    ///
    /// - Parameter name: The name of the branch to switch to.
    case switchBranch(String)
    
    /// Retrieves the creation date of the specified branch.
    ///
    /// - Parameter branch: The name of the branch.
    case getBranchCreationDate(String)
    
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
    
    /// Clears all staged changes.
    case clearStagedFiles
    
    /// Clears all unstaged changes.
    case clearUnstagedFiles
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
        case .pull:
            return "pull"
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
            
        // Branches
        case .newBranch(let name):
            return "checkout -b \(name)"
        case .listLocalBranches:
            return "branch --list"
        case .listMergedBranches:
            return "branch --merged main"
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
        case .clearStagedFiles:
            return "reset --hard HEAD"
        case .clearUnstagedFiles:
            return "clean -fd"
        }
    }
}
