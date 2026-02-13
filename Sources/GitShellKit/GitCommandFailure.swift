//
//  GitCommandFailure.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 2/8/25.
//

import Foundation

/// Captures contextual details when a git or GitHub shell command fails.
public struct GitCommandFailure: Error {
    public let command: String
    public let output: String

    public init(command: String, output: String) {
        self.command = command
        self.output = output
    }
}


// MARK: - LocalizedError
extension GitCommandFailure: LocalizedError {
    public var errorDescription: String? {
        "Git command failed: \(command)"
    }

    public var failureReason: String? {
        output
    }
}
