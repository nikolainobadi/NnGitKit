//
//  GitHubRepoStarter.swift
//  GitCommandGen
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import Foundation
import GitCommandGen

public struct GitHubRepoStarter {
    private let path: String?
    private let shell: GitShell
    private let infoProvider: RepoInfoProvider
    
    public init(path: String?, shell: GitShell, infoProvider: RepoInfoProvider) {
        self.path = path
        self.shell = shell
        self.infoProvider = infoProvider
    }
}


// MARK: - Actions
public extension GitHubRepoStarter {
    typealias GitHubURL = String
    @discardableResult
    func repoInit() throws -> GitHubURL {
        guard try shell.localGitExists(at: path) else {
            throw GitShellError.missingLocalGit
        }
        
        if try shell.remoteExists(path: path) {
            throw GitShellError.remoteRepoAlreadyExists
        }
        
        let name = try infoProvider.getProjectName()
        let username = try infoProvider.getUsername()
        let visibility = try infoProvider.getVisibility()
        let details = try infoProvider.getProjectDetails()
        let currentBranchName = try shell.runWithOutput(makeGitCommand(.getCurrentBranchName, path: path))
        
        try shell.runWithOutput(makeGitHubCommand(.createRemoteRepo(name: name, visibility: visibility.rawValue, details: details), path: path))
        try shell.runWithOutput(makeGitCommand(.addGitHubRemote(username: username, projectName: name), path: path))
        try shell.runWithOutput(makeGitCommand(.pushNewRemote(branchName: currentBranchName), path: path))
        
        return try shell.getGitHubURL(at: path)
    }
}


// MARK: - Dependencies
public enum RepoVisibility: String, CaseIterable {
    case publicRepo = "public"
    case privateRepo = "private"
}

public protocol RepoInfoProvider {
    func getUsername() throws -> String
    func getProjectName() throws -> String
    func getProjectDetails() throws -> String
    func getVisibility() throws -> RepoVisibility
}
