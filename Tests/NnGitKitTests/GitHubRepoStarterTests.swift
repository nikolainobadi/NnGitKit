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
        let (sut, shell) = makeSUT(visibility: visibility, branchPolicy: .allowNonMain, runResults: runResults)
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
        let runResults = makeRunResults(localExists: true, remoteExists: true)
        let sut = makeSUT(runResults: runResults).sut
        
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
    
    @Test("Uses configured default branch when main-only policy is enforced")
    func repoInitHonorsCustomDefaultBranch() throws {
        let defaultBranch = "develop"
        let runResults = makeRunResults(localExists: true, remoteExists: false, currentBranch: defaultBranch, githubURL: defaultURL)
        let (sut, shell) = makeSUT(branchPolicy: .mainOnly, defaultBranch: defaultBranch, runResults: runResults)
        
        let result = try sut.repoInit()
        
        #expect(result == defaultURL)
        assertShellCommands(shell: shell)
    }
    
    @Test("Fails when branch differs from configured default under main-only policy")
    func repoInitFailsWhenBranchNotDefault() throws {
        let defaultBranch = "develop"
        let runResults = makeRunResults(localExists: true, remoteExists: false, currentBranch: "feature", githubURL: defaultURL)
        let sut = makeSUT(branchPolicy: .mainOnly, defaultBranch: defaultBranch, runResults: runResults).sut
        
        #expect(throws: GitShellError.currentBranchIsNotMainBranch) {
            try sut.repoInit()
        }
    }
    
    @Test("Validation succeeds when repo is ready for init")
    func validateRepoInitSuccess() throws {
        let runResults = makeRunResults(localExists: true, remoteExists: false, currentBranch: "main")
        let (sut, shell) = makeSUT(runResults: runResults)
        
        let result = try sut.validateRepoInit()
        
        #expect(result.currentBranchName == "main")
        assertValidationCommands(shell: shell)
    }
    
    @Test("Validation throws when remote exists")
    func validateRepoInitThrowsIfRemoteExists() throws {
        let runResults = makeRunResults(localExists: true, remoteExists: true)
        let sut = makeSUT(runResults: runResults).sut
        
        #expect(throws: GitShellError.remoteRepoAlreadyExists) {
            _ = try sut.validateRepoInit()
        }
    }
    
    @Test("Throws when GitHub CLI is not available")
    func repoInitThrowsIfGhMissing() throws {
        let (sut, shell) = makeSUT(runResults: makeRunResults(), errorIndices: [0])
        
        #expect(throws: GitShellError.githubCLINotAvailable) {
            try sut.repoInit()
        }
        #expect(shell.commands.first == makeGitHubCommand(.version, path: defaultPath))
    }
    
    @Test("Throws when GitHub CLI is not authenticated")
    func repoInitThrowsIfGhNotAuthenticated() throws {
        let (sut, shell) = makeSUT(runResults: makeRunResults(), errorIndices: [1])
        
        #expect(throws: GitShellError.githubCLINotAuthenticated) {
            try sut.repoInit()
        }
        #expect(shell.commands[0] == makeGitHubCommand(.version, path: defaultPath))
        #expect(shell.commands[1] == makeGitHubCommand(.authStatus, path: defaultPath))
    }
}


// MARK: - SUT
private extension GitHubRepoStarterTests {
    func makeSUT(visibility: RepoVisibility = .publicRepo, branchPolicy: BranchPolicy = .mainOnly, defaultBranch: String = "main", path: String? = nil, runResults: [String] = [], throwError: Bool = false, errorIndices: Set<Int> = []) -> (sut: GitHubRepoStarter, shell: MockShell) {
        let shell = MockShell(runResults: runResults, throwError: throwError, errorIndices: errorIndices)
        let info = RepoInfo(name: projectName, details: projectDetails, visibility: visibility, branchPolicy: branchPolicy, defaultBranch: defaultBranch)
        let sut = GitHubRepoStarter(path: path ?? defaultPath, shell: shell, repoInfo: info)
        
        return (sut, shell)
    }
    
    func makeRunResults(localExists: Bool = true, remoteExists: Bool = false, currentBranch: String = "main", githubURL: String = "https://github.com/username/repo") -> [String] {
        return [
            "gh version",
            "gh auth status",
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
        #expect(shell.commands.count == 7)
        #expect(shell.commands[0] == makeGitHubCommand(.version, path: defaultPath))
        #expect(shell.commands[1] == makeGitHubCommand(.authStatus, path: defaultPath))
        #expect(shell.commands[2] == makeGitCommand(.localGitCheck, path: defaultPath))
        #expect(shell.commands[3] == makeGitCommand(.checkForRemote, path: defaultPath))
        #expect(shell.commands[4] == makeGitCommand(.getCurrentBranchName, path: defaultPath))
        #expect(shell.commands[5] == makeGitHubCommand(.createRemoteRepo(name: projectName, visibility: visibility.rawValue, details: projectDetails), path: defaultPath))
        #expect(shell.commands[6] == makeGitCommand(.getRemoteURL, path: defaultPath))
    }
    
    func assertValidationCommands(shell: MockShell) {
        #expect(shell.commands.count == 5)
        #expect(shell.commands[0] == makeGitHubCommand(.version, path: defaultPath))
        #expect(shell.commands[1] == makeGitHubCommand(.authStatus, path: defaultPath))
        #expect(shell.commands[2] == makeGitCommand(.localGitCheck, path: defaultPath))
        #expect(shell.commands[3] == makeGitCommand(.checkForRemote, path: defaultPath))
        #expect(shell.commands[4] == makeGitCommand(.getCurrentBranchName, path: defaultPath))
    }
}
