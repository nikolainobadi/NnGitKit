//
//  BranchSyncStatusTests.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 2/12/26.
//

import Testing
@testable import GitShellKit

// MARK: - Parsing Tests
struct BranchSyncStatusParsingTests {
    @Test("Parses 0 tab 0 as nsync")
    func parsesNsync() {
        #expect(GitShellOutput.parseSyncStatus("0\t0") == .nsync)
    }

    @Test("Parses ahead-only count")
    func parsesAhead() {
        #expect(GitShellOutput.parseSyncStatus("3\t0") == .ahead(3))
    }

    @Test("Parses behind-only count")
    func parsesBehind() {
        #expect(GitShellOutput.parseSyncStatus("0\t2") == .behind(2))
    }

    @Test("Parses diverged counts")
    func parsesDiverged() {
        #expect(GitShellOutput.parseSyncStatus("3\t2") == .diverged(ahead: 3, behind: 2))
    }

    @Test("Returns undetermined for empty string")
    func undeterminedForEmpty() {
        #expect(GitShellOutput.parseSyncStatus("") == .undetermined)
    }

    @Test("Returns undetermined for non-numeric input")
    func undeterminedForGarbage() {
        #expect(GitShellOutput.parseSyncStatus("abc") == .undetermined)
    }

    @Test("Returns undetermined for single value")
    func undeterminedForSingleValue() {
        #expect(GitShellOutput.parseSyncStatus("1") == .undetermined)
    }

    @Test("Handles whitespace around output")
    func handlesWhitespace() {
        #expect(GitShellOutput.parseSyncStatus("  3\t0\n") == .ahead(3))
    }
}


// MARK: - Integration Tests
struct BranchSyncStatusIntegrationTests {
    private let defaultPath = "/path/to/project"

    @Test("getSyncStatus returns correct status from mock output")
    func getSyncStatusReturnsCorrectStatus() throws {
        let (sut, _) = makeSUT(runResults: ["5\t0"])

        let status = try sut.getSyncStatus(local: "main", remote: "origin/main", path: defaultPath)

        #expect(status == .ahead(5))
    }

    @Test("getSyncStatus sends correct command to shell")
    func getSyncStatusSendsCorrectCommand() throws {
        let (sut, shell) = makeSUT(runResults: ["0\t0"])

        _ = try sut.getSyncStatus(local: "main", remote: "origin/main", path: defaultPath)

        #expect(shell.commands.count == 1)
        #expect(shell.commands[0] == makeGitCommand(.compareBranchAndRemote(local: "main", remote: "origin/main"), path: defaultPath))
    }
}


// MARK: - Helpers
private extension BranchSyncStatusIntegrationTests {
    func makeSUT(runResults: [String]) -> (sut: MockShell, shell: MockShell) {
        let shell = MockShell(runResults: runResults)
        return (shell, shell)
    }
}
