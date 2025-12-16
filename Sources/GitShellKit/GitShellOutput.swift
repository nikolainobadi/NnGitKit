//
//  GitShellOutput.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import Foundation

/// Helpers that centralize parsing assumptions for Git and GitHub CLI output.
enum GitShellOutput {
    /// Determines whether a shell output represents a true value.
    static func isTrue(_ output: String) -> Bool {
        output.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
    }
    
    /// Determines whether the list of remotes includes `origin`.
    static func containsOriginRemote(_ output: String) -> Bool {
        output
            .split(separator: "\n")
            .map(String.init)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .contains("origin")
    }
}
