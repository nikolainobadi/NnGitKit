//
//  GitCommandFailure.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 2/8/25.
//

/// Captures contextual details when a git or GitHub shell command fails.
public struct GitCommandFailure: Error {
    public let command: String
    public let output: String
    
    public init(command: String, output: String) {
        self.command = command
        self.output = output
    }
}
