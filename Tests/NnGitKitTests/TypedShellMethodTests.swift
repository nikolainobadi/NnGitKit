//
//  TypedShellMethodTests.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 2/12/26.
//

import Testing
import Foundation
@testable import GitShellKit

// MARK: - Parsing Tests
struct TypedShellParsingTests {
    // MARK: - parseBranchList
    @Test("Parses branch list stripping current branch marker")
    func parseBranchListStripsCurrentMarker() {
        let output = "* main\n  feature/login\n  develop\n"
        let result = GitShellOutput.parseBranchList(output)
        #expect(result == ["main", "feature/login", "develop"])
    }

    @Test("Parses branch list with whitespace and empty lines")
    func parseBranchListHandlesWhitespace() {
        let output = "  main  \n\n  feature  \n"
        let result = GitShellOutput.parseBranchList(output)
        #expect(result == ["main", "feature"])
    }

    @Test("Returns empty array for empty branch output")
    func parseBranchListEmpty() {
        #expect(GitShellOutput.parseBranchList("").isEmpty)
    }

    // MARK: - parseRemoteBranchList
    @Test("Parses remote branches stripping origin prefix")
    func parseRemoteBranchListStripsOrigin() {
        let output = "  origin/main\n  origin/develop\n  origin/feature\n"
        let result = GitShellOutput.parseRemoteBranchList(output)
        #expect(result == ["main", "develop", "feature"])
    }

    @Test("Filters out HEAD pointer entries")
    func parseRemoteBranchListFiltersHead() {
        let output = "  origin/HEAD -> origin/main\n  origin/main\n  origin/develop\n"
        let result = GitShellOutput.parseRemoteBranchList(output)
        #expect(result == ["main", "develop"])
    }

    @Test("Returns empty array for empty remote output")
    func parseRemoteBranchListEmpty() {
        #expect(GitShellOutput.parseRemoteBranchList("").isEmpty)
    }

    // MARK: - parseLocalChanges
    @Test("Parses porcelain status lines")
    func parseLocalChangesHandlesPorcelain() {
        let output = " M file1.swift\nA  file2.swift\n?? file3.swift\n"
        let result = GitShellOutput.parseLocalChanges(output)
        #expect(result == ["M file1.swift", "A  file2.swift", "?? file3.swift"])
    }

    @Test("Returns empty array for clean working tree")
    func parseLocalChangesEmpty() {
        #expect(GitShellOutput.parseLocalChanges("").isEmpty)
    }

    // MARK: - parseBranchCreationDate
    @Test("Parses valid ISO date string")
    func parseBranchCreationDateValid() {
        let output = "2025-03-20 14:30:00 +0000\n"
        let result = GitShellOutput.parseBranchCreationDate(output)
        #expect(result != nil)
    }

    @Test("Returns nil for empty string")
    func parseBranchCreationDateEmpty() {
        #expect(GitShellOutput.parseBranchCreationDate("") == nil)
    }

    @Test("Returns nil for garbage input")
    func parseBranchCreationDateGarbage() {
        #expect(GitShellOutput.parseBranchCreationDate("not-a-date") == nil)
    }

    // MARK: - parseCommitLog
    @Test("Parses valid multi-line commit log into CommitInfo array")
    func parseCommitLogValid() {
        let output = "abc1234\tFix login bug\tJane Doe\tjane@example.com\t2 days ago\ndef5678\tAdd tests\tJohn Smith\tjohn@example.com\t3 hours ago"
        let result = GitShellOutput.parseCommitLog(output)

        #expect(result.count == 2)
        #expect(result[0] == CommitInfo(hash: "abc1234", message: "Fix login bug", authorName: "Jane Doe", authorEmail: "jane@example.com", relativeDate: "2 days ago"))
        #expect(result[1] == CommitInfo(hash: "def5678", message: "Add tests", authorName: "John Smith", authorEmail: "john@example.com", relativeDate: "3 hours ago"))
    }

    @Test("Returns empty array for empty commit log output")
    func parseCommitLogEmpty() {
        #expect(GitShellOutput.parseCommitLog("").isEmpty)
    }

    @Test("Skips malformed lines in commit log")
    func parseCommitLogSkipsMalformed() {
        let output = "abc1234\tFix bug\tJane\tjane@example.com\t2 days ago\nmalformed line without tabs\ndef5678\tAdd tests\tJohn\tjohn@example.com\t3 hours ago"
        let result = GitShellOutput.parseCommitLog(output)

        #expect(result.count == 2)
        #expect(result[0].hash == "abc1234")
        #expect(result[1].hash == "def5678")
    }
}


// MARK: - Integration Tests
struct TypedShellMethodIntegrationTests {
    private let defaultPath = "/path/to/project"

    @Test("listLocalBranchNames sends correct command and parses result")
    func listLocalBranchNames() throws {
        let (sut, shell) = makeSUT(runResults: ["* main\n  develop\n"])

        let result = try sut.listLocalBranchNames(path: defaultPath)

        #expect(result == ["main", "develop"])
        #expect(shell.commands.count == 1)
        #expect(shell.commands[0] == makeGitCommand(.listLocalBranches, path: defaultPath))
    }

    @Test("listRemoteBranchNames sends correct command and parses result")
    func listRemoteBranchNames() throws {
        let (sut, shell) = makeSUT(runResults: ["  origin/main\n  origin/develop\n"])

        let result = try sut.listRemoteBranchNames(path: defaultPath)

        #expect(result == ["main", "develop"])
        #expect(shell.commands.count == 1)
        #expect(shell.commands[0] == makeGitCommand(.listRemoteBranches, path: defaultPath))
    }

    @Test("getLocalChanges sends correct command and parses result")
    func getLocalChanges() throws {
        let (sut, shell) = makeSUT(runResults: [" M file.swift\n"])

        let result = try sut.getLocalChanges(path: defaultPath)

        #expect(result == ["M file.swift"])
        #expect(shell.commands.count == 1)
        #expect(shell.commands[0] == makeGitCommand(.getLocalChanges, path: defaultPath))
    }

    @Test("getBranchCreationDate sends correct command and parses result")
    func getBranchCreationDate() throws {
        let (sut, shell) = makeSUT(runResults: ["2025-03-20 14:30:00 +0000"])

        let result = try sut.getBranchCreationDate(name: "feature", path: defaultPath)

        #expect(result != nil)
        #expect(shell.commands.count == 1)
        #expect(shell.commands[0] == makeGitCommand(.getBranchCreationDate(branchName: "feature"), path: defaultPath))
    }

    @Test("getBranchCreationDate returns nil for empty output")
    func getBranchCreationDateReturnsNilForEmpty() throws {
        let (sut, _) = makeSUT(runResults: [""])

        let result = try sut.getBranchCreationDate(name: "feature", path: defaultPath)

        #expect(result == nil)
    }

    @Test("listLocalBranchNames returns empty array for empty output")
    func listLocalBranchNamesEmpty() throws {
        let (sut, _) = makeSUT(runResults: [""])

        let result = try sut.listLocalBranchNames(path: defaultPath)

        #expect(result.isEmpty)
    }

    @Test("getRecentCommits sends correct command and returns parsed result")
    func getRecentCommits() throws {
        let (sut, shell) = makeSUT(runResults: ["abc1234\tFix bug\tJane\tjane@example.com\t2 days ago"])

        let result = try sut.getRecentCommits(count: 5, path: defaultPath)

        #expect(result.count == 1)
        #expect(result[0].hash == "abc1234")
        #expect(shell.commands.count == 1)
        #expect(shell.commands[0] == makeGitCommand(.log(count: 5, format: GitShellOutput.commitLogFormat), path: defaultPath))
    }

    @Test("getRecentCommits returns empty array for empty output")
    func getRecentCommitsEmpty() throws {
        let (sut, _) = makeSUT(runResults: [""])

        let result = try sut.getRecentCommits(path: defaultPath)

        #expect(result.isEmpty)
    }
}


// MARK: - Helpers
private extension TypedShellMethodIntegrationTests {
    func makeSUT(runResults: [String]) -> (sut: MockShell, shell: MockShell) {
        let shell = MockShell(runResults: runResults)
        return (shell, shell)
    }
}
