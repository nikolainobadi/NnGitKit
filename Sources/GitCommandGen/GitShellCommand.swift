//
//  GitShellCommand.swift
//  GitCommandGen
//
//  Created by Nikolai Nobadi on 3/20/25.
//

public enum GitShellCommand {
    // git init
    case gitInit, addAll, commit(String)
    
    // repository
    case pull
    case push
    case fetchOrigin
    case pruneOrigin
    case getRemoteURL
    case localGitCheck
    case clone(String)
    case rebase(String)
    case checkForRemote
    case pushNewRemote(branchName: String)
    case addGitHubRemote(username: String, projectName: String)
    
    
    // branches
    case newBranch(String)
    case listLocalBranches
    case listMergedBranches
    case listRemoteBranches
    case getCurrentBranchName
    case switchBranch(String)
    case getBranchCreationDate(String)
    case deleteBranch(name: String, forced: Bool)
    case compareBranchAndRemote(local: String, remote: String)
    
    // file tracking
    case getLocalChanges
    case clearStagedFiles
    case clearUnstagedFiles
}


// MARK: - Arg String
extension GitShellCommand {
    var arg: String {
        switch self {
        // Git Init
        case .gitInit:
            return "init"
        case .addAll:
            return "add ."
        case .commit(let message):
            return "commit -m \"\(message)\""
            
        // repository
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
            return "push -u origin \(branchName )"
        case .addGitHubRemote(let username, let projectName):
            return "remote add origin https://github.com/\(username)/\(projectName).git"
            
        // branches
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
        
        // file tracking
        case .getLocalChanges:
            return "status --porcelain"
        case .clearStagedFiles:
            return "reset --hard HEAD"
        case .clearUnstagedFiles:
            return "clean -fd"
        }
    }
}
