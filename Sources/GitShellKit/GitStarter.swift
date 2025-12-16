//
//  GitStarter.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import GitCommandGen

/// A utility for initializing Git repositories and performing basic Git operations.
public struct GitStarter {
    private let path: String?
    private let shell: GitShell
    private let ignoreErrors: Bool

    /// Initializes a `GitStarter` with the given path, shell, and error handling preference.
    ///
    /// - Parameters:
    ///   - path: The file system path where the repository should be initialized.
    ///   - shell: The shell implementation for running Git commands.
    ///   - ignoreErrors: A flag indicating whether to ignore errors (default is `false`).
    public init(path: String?, shell: GitShell, ignoreErrors: Bool = false) {
        self.path = path
        self.shell = shell
        self.ignoreErrors = ignoreErrors
    }
}

// MARK: - Actions
public extension GitStarter {
    /// Initializes a new Git repository at the specified path.
    ///
    /// If a Git repository already exists and `ignoreErrors` is `false`, an error will be thrown.
    ///
    /// - Throws: `GitShellError.localGitAlreadyExists` if a repository already exists.
    func gitInit() throws {
        _ = try gitInit(mode: .execute)
    }
    
    /// Initializes a new Git repository at the specified path using the requested execution mode.
    ///
    /// - Parameter mode: Whether to execute commands or return a planned sequence.
    /// - Returns: The commands that were executed or planned.
    /// - Throws: `GitShellError.localGitAlreadyExists` if a repository already exists.
    @discardableResult
    func gitInit(mode: ExecutionMode) throws -> [String] {
        var commands: [String] = []
        
        let localGitCheck = makeGitCommand(.localGitCheck, path: path)
        commands.append(localGitCheck)
        if mode == .execute {
            let exists = GitShellOutput.isTrue(try shell.runWithOutput(localGitCheck))
            if exists && !ignoreErrors {
                throw GitShellError.localGitAlreadyExists
            }
        }

        let initCommand = makeGitCommand(.gitInit, path: path)
        commands.append(initCommand)
        if mode == .execute {
            try shell.runWithOutput(initCommand)
        }
        
        let addCommand = makeGitCommand(.addAll, path: path)
        commands.append(addCommand)
        if mode == .execute {
            try shell.runWithOutput(addCommand)
        }
        
        let commitCommand = makeGitCommand(.commit(message: "Initial Commit"), path: path)
        commands.append(commitCommand)
        if mode == .execute {
            try shell.runWithOutput(commitCommand)
        }
        
        return commands
    }
}
