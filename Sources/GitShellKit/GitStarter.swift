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
        if try shell.localGitExists(at: path), !ignoreErrors {
            throw GitShellError.localGitAlreadyExists
        }

        try shell.runWithOutput(makeGitCommand(.gitInit, path: path))
        try shell.runWithOutput(makeGitCommand(.addAll, path: path))
        try shell.runWithOutput(makeGitCommand(.commit("Initial Commit"), path: path))
    }
}
