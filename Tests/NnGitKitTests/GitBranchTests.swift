//
//  GitBranchTests.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 2/12/26.
//

import Testing
import Foundation
@testable import GitShellKit

struct GitBranchTests {
    private let defaultPath = "/path/to/project"

    @Test("Loads branches with full metadata for multiple branches")
    func loadBranchesFullScenario() throws {
        // Branches: main (current, merged, synced), feature (unmerged, ahead), local-only (no remote)
        let (sut, shell) = makeSUT(runResults: [
            "* main\n  feature\n  local-only",          // listLocalBranches
            "main",                                      // getCurrentBranchName
            "* main\n  feature",                         // listMergedBranches (feature merged too for this test)
            "  origin/main\n  origin/feature",           // listRemoteBranches
            "2025-01-15 10:00:00 +0000",                 // getBranchCreationDate(main)
            "0\t0",                                      // getSyncStatus(main)
            "2025-02-01 14:30:00 +0000",                 // getBranchCreationDate(feature)
            "2\t0",                                      // getSyncStatus(feature)
            "2025-03-01 09:00:00 +0000",                 // getBranchCreationDate(local-only)
        ])

        let branches = try sut.loadBranches(mainBranch: "main", path: defaultPath)

        #expect(branches.count == 3)

        // main: current, merged, synced
        #expect(branches[0].name == "main")
        #expect(branches[0].isCurrentBranch)
        #expect(branches[0].isMerged)
        #expect(branches[0].syncStatus == .nsync)
        #expect(branches[0].creationDate != nil)

        // feature: not current, merged, ahead
        #expect(branches[1].name == "feature")
        #expect(!branches[1].isCurrentBranch)
        #expect(branches[1].isMerged)
        #expect(branches[1].syncStatus == .ahead(2))
        #expect(branches[1].creationDate != nil)

        // local-only: not current, not merged, no remote
        #expect(branches[2].name == "local-only")
        #expect(!branches[2].isCurrentBranch)
        #expect(!branches[2].isMerged)
        #expect(branches[2].syncStatus == .noRemoteBranch)
        #expect(branches[2].creationDate != nil)

        // Verify first 4 commands are the batch queries
        #expect(shell.commands[0] == makeGitCommand(.listLocalBranches, path: defaultPath))
        #expect(shell.commands[1] == makeGitCommand(.getCurrentBranchName, path: defaultPath))
        #expect(shell.commands[2] == makeGitCommand(.listMergedBranches(branchName: "main"), path: defaultPath))
        #expect(shell.commands[3] == makeGitCommand(.listRemoteBranches, path: defaultPath))
    }

    @Test("Verifies correct command sequence for single branch")
    func loadBranchesSingleBranch() throws {
        let (sut, shell) = makeSUT(runResults: [
            "* main",                           // listLocalBranches
            "main",                              // getCurrentBranchName
            "* main",                            // listMergedBranches
            "  origin/main",                     // listRemoteBranches
            "2025-01-15 10:00:00 +0000",         // getBranchCreationDate(main)
            "0\t0",                              // getSyncStatus(main)
        ])

        let branches = try sut.loadBranches(mainBranch: "main", path: defaultPath)

        #expect(branches.count == 1)
        #expect(branches[0].name == "main")
        // 4 batch + 1 creationDate + 1 syncStatus = 6 commands
        #expect(shell.commands.count == 6)
    }

    @Test("Returns empty array for empty branch list")
    func loadBranchesEmpty() throws {
        let (sut, _) = makeSUT(runResults: [""])

        let branches = try sut.loadBranches(mainBranch: "main", path: defaultPath)

        #expect(branches.isEmpty)
    }

    @Test("Remote fetch failure gives all branches noRemoteBranch status")
    func loadBranchesRemoteFetchFailure() throws {
        // errorIndices[3] = listRemoteBranches fails
        let shell = MockShell(
            runResults: [
                "* main",                           // listLocalBranches
                "main",                              // getCurrentBranchName
                "* main",                            // listMergedBranches
                "",                                  // placeholder for error
                "2025-01-15 10:00:00 +0000",         // getBranchCreationDate(main)
            ],
            errorIndices: [3]
        )

        let branches = try shell.loadBranches(mainBranch: "main", path: defaultPath)

        #expect(branches.count == 1)
        #expect(branches[0].syncStatus == .noRemoteBranch)
    }

    @Test("Creation date failure returns nil gracefully")
    func loadBranchesCreationDateFailure() throws {
        // errorIndices[4] = getBranchCreationDate fails (error does not consume a result)
        let shell = MockShell(
            runResults: [
                "* main",                           // listLocalBranches
                "main",                              // getCurrentBranchName
                "* main",                            // listMergedBranches
                "  origin/main",                     // listRemoteBranches
                "0\t0",                              // getSyncStatus(main)
            ],
            errorIndices: [4]
        )

        let branches = try shell.loadBranches(mainBranch: "main", path: defaultPath)

        #expect(branches.count == 1)
        #expect(branches[0].creationDate == nil)
        #expect(branches[0].syncStatus == .nsync)
    }

    @Test("Sync status failure returns undetermined")
    func loadBranchesSyncStatusFailure() throws {
        // errorIndices[5] = getSyncStatus fails
        let shell = MockShell(
            runResults: [
                "* main",                           // listLocalBranches
                "main",                              // getCurrentBranchName
                "* main",                            // listMergedBranches
                "  origin/main",                     // listRemoteBranches
                "2025-01-15 10:00:00 +0000",         // getBranchCreationDate(main)
                "",                                  // placeholder for error
            ],
            errorIndices: [5]
        )

        let branches = try shell.loadBranches(mainBranch: "main", path: defaultPath)

        #expect(branches.count == 1)
        #expect(branches[0].syncStatus == .undetermined)
    }

    @Test("Uses custom branch name for merged check")
    func loadBranchesMergedIntoCustomBranch() throws {
        let (sut, shell) = makeSUT(runResults: [
            "* develop",                        // listLocalBranches
            "develop",                           // getCurrentBranchName
            "* develop",                         // listMergedBranches(develop)
            "",                                  // listRemoteBranches (empty)
            "2025-01-15 10:00:00 +0000",         // getBranchCreationDate(develop)
        ])

        let branches = try sut.loadBranches(mainBranch: "develop", path: defaultPath)

        #expect(branches.count == 1)
        #expect(branches[0].isMerged)
        #expect(shell.commands[2] == makeGitCommand(.listMergedBranches(branchName: "develop"), path: defaultPath))
    }
}


// MARK: - Helpers
private extension GitBranchTests {
    func makeSUT(runResults: [String]) -> (sut: MockShell, shell: MockShell) {
        let shell = MockShell(runResults: runResults)
        return (shell, shell)
    }
}
