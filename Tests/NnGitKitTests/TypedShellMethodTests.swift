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
}


// MARK: - Helpers
private extension TypedShellMethodIntegrationTests {
    func makeSUT(runResults: [String]) -> (sut: MockShell, shell: MockShell) {
        let shell = MockShell(runResults: runResults)
        return (shell, shell)
    }
}
