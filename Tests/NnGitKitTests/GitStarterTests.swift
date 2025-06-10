//
//  GitStarterTests.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import Testing
@testable import GitShellKit

struct GitStarterTests {
    private let defaultPath = "/path/to/project"
}


// MARK: - Unit Tests
extension GitStarterTests {
    @Test("Successfully initializes a new Git repository when no local git exists")
    func gitInitSuccess() throws {
        let (sut, shell) = makeSUT(path: defaultPath)
        
        try sut.gitInit()
        
        assertShellCommands(shell: shell)
    }

    @Test("Throws error if local Git repository already exists")
    func gitInitThrowsIfLocalGitExists() throws {
        let sut = makeSUT(runResults: ["true"]).sut

        #expect(throws: GitShellError.localGitAlreadyExists) {
            try sut.gitInit()
        }
    }

    @Test("Ignores error when ignoreErrors is true")
    func gitInitIgnoresError() throws {
        let (sut, shell) = makeSUT(runResults: ["true"], ignoreErrors: true)
        
        try sut.gitInit()
        
        assertShellCommands(shell: shell)
    }
}


// MARK: - SUT
private extension GitStarterTests {
    func makeSUT(path: String? = nil, runResults: [String] = [], ignoreErrors: Bool = false, throwError: Bool = false) -> (sut: GitStarter, shell: MockShell) {
        let shell = MockShell(runResults: runResults, throwError: throwError)
        let sut = GitStarter(path: path ?? defaultPath, shell: shell, ignoreErrors: ignoreErrors)
        
        return (sut, shell)
    }
}


// MARK: - Assertion Helpers
private extension GitStarterTests {
    func assertShellCommands(shell: MockShell) {
        #expect(shell.commands.count == 4)
        #expect(shell.commands[0] == makeGitCommand(.localGitCheck, path: defaultPath))
        #expect(shell.commands[1] == makeGitCommand(.gitInit, path: defaultPath))
        #expect(shell.commands[2] == makeGitCommand(.addAll, path: defaultPath))
        #expect(shell.commands[3] == makeGitCommand(.commit(message: "Initial Commit"), path: defaultPath))
    }
}
