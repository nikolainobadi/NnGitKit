//
//  GitShellHelperTests.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 2/8/25.
//

import Testing
@testable import GitShellKit

struct GitShellHelperTests {
    private let defaultPath = "/path/to/project"
}


// MARK: - Default Branch
extension GitShellHelperTests {
    @Test("Resolves default branch from origin HEAD when available")
    func defaultBranchUsesRemoteHead() throws {
        let shell = makeShell(runResults: ["true", "origin", "refs/remotes/origin/main"])
        
        let branch = try shell.getDefaultBranch(at: defaultPath)
        
        #expect(branch == "main")
        #expect(shell.commands.count == 3)
        #expect(shell.commands[0] == makeGitCommand(.localGitCheck, path: defaultPath))
        #expect(shell.commands[1] == makeGitCommand(.checkForRemote, path: defaultPath))
        #expect(shell.commands[2] == makeGitCommand(.getRemoteDefaultBranch, path: defaultPath))
    }
    
    @Test("Falls back to init.defaultBranch when origin HEAD is missing")
    func defaultBranchFallsBackToConfig() throws {
        let shell = makeShell(runResults: ["true", "origin", "HEAD", "develop"])
        
        let branch = try shell.getDefaultBranch(at: defaultPath)
        
        #expect(branch == "develop")
        #expect(shell.commands.count == 4)
        #expect(shell.commands[0] == makeGitCommand(.localGitCheck, path: defaultPath))
        #expect(shell.commands[1] == makeGitCommand(.checkForRemote, path: defaultPath))
        #expect(shell.commands[2] == makeGitCommand(.getRemoteDefaultBranch, path: defaultPath))
        #expect(shell.commands[3] == makeGitCommand(.getInitDefaultBranch, path: defaultPath))
    }
    
    @Test("Defaults to main when no remote and no config")
    func defaultBranchFallsBackToMain() throws {
        let shell = makeShell(runResults: ["true", "upstream", ""])
        
        let branch = try shell.getDefaultBranch(at: defaultPath)
        
        #expect(branch == "main")
        #expect(shell.commands.count == 3)
        #expect(shell.commands[0] == makeGitCommand(.localGitCheck, path: defaultPath))
        #expect(shell.commands[1] == makeGitCommand(.checkForRemote, path: defaultPath))
        #expect(shell.commands[2] == makeGitCommand(.getInitDefaultBranch, path: defaultPath))
    }
}


// MARK: - Repo State
extension GitShellHelperTests {
    @Test("Inspects repo state with existing local git and remotes")
    func inspectRepoStateWithRemote() throws {
        let shell = makeShell(runResults: ["true", "origin\nupstream", "feature/test"])
        
        let state = try shell.inspectRepoState(at: defaultPath)
        
        #expect(state.hasLocalGit)
        #expect(state.hasRemote)
        #expect(state.remotes == ["origin", "upstream"])
        #expect(state.currentBranch == "feature/test")
        #expect(shell.commands.count == 3)
        #expect(shell.commands[0] == makeGitCommand(.localGitCheck, path: defaultPath))
        #expect(shell.commands[1] == makeGitCommand(.checkForRemote, path: defaultPath))
        #expect(shell.commands[2] == makeGitCommand(.getCurrentBranchName, path: defaultPath))
    }
    
    @Test("Returns empty state when git is missing")
    func inspectRepoStateWithoutLocalGit() throws {
        let shell = makeShell(runResults: ["false"])
        
        let state = try shell.inspectRepoState(at: defaultPath)
        
        #expect(!state.hasLocalGit)
        #expect(!state.hasRemote)
        #expect(state.remotes.isEmpty)
        #expect(state.currentBranch.isEmpty)
        #expect(shell.commands.count == 1)
        #expect(shell.commands[0] == makeGitCommand(.localGitCheck, path: defaultPath))
    }
}


// MARK: - Validate GitHub CLI
extension GitShellHelperTests {
    @Test("validateGitHubCLI sends version and auth status commands on success")
    func validateGitHubCLISuccess() throws {
        let shell = makeShell(runResults: ["", ""])

        try shell.validateGitHubCLI(path: defaultPath)

        #expect(shell.commands.count == 2)
        #expect(shell.commands[0] == makeGitHubCommand(.version, path: defaultPath))
        #expect(shell.commands[1] == makeGitHubCommand(.authStatus, path: defaultPath))
    }

    @Test("validateGitHubCLI throws githubCLINotAvailable when version check fails")
    func validateGitHubCLINotAvailable() throws {
        let shell = MockShell(runResults: [], errorIndices: [0])

        #expect(throws: GitShellError.githubCLINotAvailable) {
            try shell.validateGitHubCLI(path: defaultPath)
        }
    }

    @Test("validateGitHubCLI throws githubCLINotAuthenticated when auth check fails")
    func validateGitHubCLINotAuthenticated() throws {
        let shell = MockShell(runResults: [""], errorIndices: [1])

        #expect(throws: GitShellError.githubCLINotAuthenticated) {
            try shell.validateGitHubCLI(path: defaultPath)
        }
    }
}


// MARK: - Helpers
private extension GitShellHelperTests {
    func makeShell(runResults: [String]) -> MockShell {
        MockShell(runResults: runResults)
    }
}
