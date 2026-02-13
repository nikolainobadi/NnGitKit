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
        let shell = makeShell(runResults: [
            "true",                         // localGitCheck
            "origin\nupstream",             // checkForRemote
            "feature/test",                 // getCurrentBranchName
            " M file.swift",                // getLocalChanges
            "true",                         // getDefaultBranch -> localGitCheck
            "origin",                       // getDefaultBranch -> checkForRemote
            "refs/remotes/origin/main",     // getDefaultBranch -> getRemoteDefaultBranch
            "0\t0",                         // compareBranchAndRemote (syncStatus)
            "file1.swift\nfile2.swift\nfile3.swift" // listTrackedFiles
        ])

        let state = try shell.inspectRepoState(at: defaultPath)

        #expect(state.hasLocalGit)
        #expect(state.hasRemote)
        #expect(state.remotes == ["origin", "upstream"])
        #expect(state.currentBranch == "feature/test")
        #expect(state.hasUncommittedChanges)
        #expect(state.defaultBranch == "main")
        #expect(state.syncStatus == .nsync)
        #expect(state.trackedFileCount == 3)
        #expect(shell.commands.count == 9)
    }

    @Test("Returns empty state when git is missing")
    func inspectRepoStateWithoutLocalGit() throws {
        let shell = makeShell(runResults: ["false"])

        let state = try shell.inspectRepoState(at: defaultPath)

        #expect(!state.hasLocalGit)
        #expect(!state.hasRemote)
        #expect(state.remotes.isEmpty)
        #expect(state.currentBranch.isEmpty)
        #expect(!state.hasUncommittedChanges)
        #expect(state.defaultBranch == nil)
        #expect(state.syncStatus == nil)
        #expect(state.trackedFileCount == 0)
        #expect(shell.commands.count == 1)
    }

    @Test("Inspects repo state without remote sets syncStatus to nil")
    func inspectRepoStateWithoutRemote() throws {
        let shell = makeShell(runResults: [
            "true",         // localGitCheck
            "upstream",     // checkForRemote (no origin)
            "main",         // getCurrentBranchName
            "",             // getLocalChanges (clean)
            "true",         // getDefaultBranch -> localGitCheck
            "upstream",     // getDefaultBranch -> checkForRemote (no origin)
            "main",         // getDefaultBranch -> getInitDefaultBranch
            "file.swift"    // listTrackedFiles
        ])

        let state = try shell.inspectRepoState(at: defaultPath)

        #expect(state.hasLocalGit)
        #expect(!state.hasRemote)
        #expect(!state.hasUncommittedChanges)
        #expect(state.defaultBranch == "main")
        #expect(state.syncStatus == nil)
        #expect(state.trackedFileCount == 1)
    }

    @Test("No uncommitted changes when working tree is clean")
    func inspectRepoStateCleanWorkingTree() throws {
        let shell = makeShell(runResults: [
            "true",                         // localGitCheck
            "origin",                       // checkForRemote
            "main",                         // getCurrentBranchName
            "",                             // getLocalChanges (empty = clean)
            "true",                         // getDefaultBranch -> localGitCheck
            "origin",                       // getDefaultBranch -> checkForRemote
            "refs/remotes/origin/main",     // getDefaultBranch -> getRemoteDefaultBranch
            "0\t0",                         // compareBranchAndRemote
            "a.swift\nb.swift"              // listTrackedFiles
        ])

        let state = try shell.inspectRepoState(at: defaultPath)

        #expect(!state.hasUncommittedChanges)
        #expect(state.trackedFileCount == 2)
    }

    @Test("SyncStatus failure falls back to noRemoteBranch")
    func inspectRepoStateSyncStatusFailure() throws {
        // Command indices:
        // 0: localGitCheck, 1: checkForRemote, 2: getCurrentBranchName
        // 3: getLocalChanges, 4-6: getDefaultBranch (3 commands)
        // 7: compareBranchAndRemote (ERROR), 8: listTrackedFiles
        let shell = MockShell(
            runResults: [
                "true",                         // localGitCheck
                "origin",                       // checkForRemote
                "main",                         // getCurrentBranchName
                "",                             // getLocalChanges
                "true",                         // getDefaultBranch -> localGitCheck
                "origin",                       // getDefaultBranch -> checkForRemote
                "refs/remotes/origin/main",     // getDefaultBranch -> getRemoteDefaultBranch
                "",                             // placeholder consumed by error index
                "file.swift"                    // listTrackedFiles
            ],
            errorIndices: [7]
        )

        let state = try shell.inspectRepoState(at: defaultPath)

        #expect(state.syncStatus == .noRemoteBranch)
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
