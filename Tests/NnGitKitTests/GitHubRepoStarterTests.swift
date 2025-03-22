//
//  GitHubRepoStarterTests.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import Testing
@testable import GitShellKit

struct GitHubRepoStarterTests {
    private let projectName = "projectName"
    private let projectDetails = "project details"
    private let defaultPath = "/path/to/project"
    private let defaultURL = "https://github.com/username/repo"
}


// MARK: - Unit Tests
extension GitHubRepoStarterTests {
    @Test("Successfully initializes a new GitHub repository when local git exists, remote does not exist, and is on main branch", arguments: RepoVisibility.allCases)
    func repoInitSuccess(visibility: RepoVisibility) throws {
        let runResults = makeRunResults(localExists: true, remoteExists: false, currentBranch: "main", githubURL: defaultURL)
        let (sut, shell) = makeSUT(visibility: visibility, runResults: runResults)
        let result = try sut.repoInit()
        
        #expect(result == defaultURL)
        assertShellCommands(shell: shell, visibility: visibility)
    }
    
    @Test("Successfully initializes a new GitHub repository when local git exists, remote does not exist, and NOT on main branch BUT can upload to non-main branch", arguments: RepoVisibility.allCases)
    func repoInitSuccessNonMainBranch(visibility: RepoVisibility) throws {
        let runResults = makeRunResults(localExists: true, remoteExists: false, currentBranch: "feature", githubURL: defaultURL)
        let (sut, shell) = makeSUT(visibility: visibility, canUploadNonMainBranch: true, runResults: runResults)
        let result = try sut.repoInit()
        
        #expect(result == defaultURL)
        assertShellCommands(shell: shell, visibility: visibility)
    }
    
    @Test("Throws error if local Git repository does not exist")
    func repoInitThrowsIfLocalGitMissing() throws {
        let sut = makeSUT(runResults: ["false"]).sut
        
        #expect(throws: GitShellError.missingLocalGit) {
            try sut.repoInit()
        }
    }
    
    @Test("Throws error if remote already exists")
    func repoInitThrowsIfRemoteExists() throws {
        let sut = makeSUT(runResults: ["true", "origin"]).sut
        
        #expect(throws: GitShellError.remoteRepoAlreadyExists) {
            try sut.repoInit()
        }
    }
    
    @Test("Throws error if current branch is not main AND cannot upload on non-main branch")
    func repoInitThrowsIfNotOnMainBranch() throws {
        let runResults = makeRunResults(currentBranch: "featureBranch")
        let sut = makeSUT(runResults: runResults).sut
        
        #expect(throws: GitShellError.currentBranchIsNotMainBranch) {
            try sut.repoInit()
        }
    }
}


// MARK: - SUT
private extension GitHubRepoStarterTests {
    func makeSUT(visibility: RepoVisibility = .publicRepo, canUploadNonMainBranch: Bool = false, path: String? = nil, runResults: [String] = [], throwError: Bool = false) -> (sut: GitHubRepoStarter, shell: MockShell) {
        let shell = MockShell(runResults: runResults, throwError: throwError)
        let info = RepoInfo(name: projectName, details: projectDetails, visibility: visibility, canUploadFromNonMainBranch: canUploadNonMainBranch)
        let sut = GitHubRepoStarter(path: path ?? defaultPath, shell: shell, repoInfo: info)
        
        return (sut, shell)
    }
    
    func makeRunResults(localExists: Bool = true, remoteExists: Bool = false, currentBranch: String = "main", githubURL: String = "https://github.com/username/repo") -> [String] {
        return [
            localExists ? "true" : "false",
            remoteExists ? "origin" : "",
            currentBranch,
            "creatingRemoteRepo",
            githubURL
        ]
    }
}


// MARK: - Assertion Helpers
private extension GitHubRepoStarterTests {
    func assertShellCommands(shell: MockShell, visibility: RepoVisibility = .publicRepo) {
        #expect(shell.commands.count == 5)
        #expect(shell.commands[0] == makeGitCommand(.localGitCheck, path: defaultPath))
        #expect(shell.commands[1] == makeGitCommand(.checkForRemote, path: defaultPath))
        #expect(shell.commands[2] == makeGitCommand(.getCurrentBranchName, path: defaultPath))
        #expect(shell.commands[3] == makeGitHubCommand(.createRemoteRepo(name: projectName, visibility: visibility.rawValue, details: projectDetails), path: defaultPath))
        #expect(shell.commands[4] == makeGitCommand(.getRemoteURL, path: defaultPath))
    }
}
