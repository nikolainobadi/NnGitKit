//
//  GitStarter.swift
//  GitCommandGen
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import GitCommandGen

public struct GitStarter {
    private let path: String?
    private let shell: GitShell
    
    public init(path: String?, shell: GitShell) {
        self.path = path
        self.shell = shell
    }
}


// MARK: - Actions
public extension GitStarter {
    func gitInit() throws {
        if try !shell.localGitExists(at: path) {
            try shell.runWithOutput(makeGitCommand(.gitInit, path: path))
            try shell.runWithOutput(makeGitCommand(.addAll, path: path))
            try shell.runWithOutput(makeGitCommand(.commit("Initial Commit"), path: path))
        }
    }
}
