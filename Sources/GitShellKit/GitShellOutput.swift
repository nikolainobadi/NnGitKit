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
    
    /// Normalizes various Git remote URL formats into a GitHub HTTPS URL.
    ///
    /// Supported inputs:
    /// - git@github.com:user/repo.git
    /// - git@github.com:user/repo
    /// - https://github.com/user/repo.git
    /// - https://github.com/user/repo
    /// - github.com:user/repo.git
    /// - github.com/user/repo.git
    ///
    /// If normalization fails, the original string is returned unchanged.
    static func normalizeGitHubURL(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        
        // Strip trailing .git if present
        let withoutGitSuffix = trimmed.hasSuffix(".git") ? String(trimmed.dropLast(4)) : trimmed
        
        // Replace scp-like separators and leading git@ if present
        let normalized = withoutGitSuffix
            .replacingOccurrences(of: "git@", with: "")
            .replacingOccurrences(of: "github.com:", with: "github.com/")
        
        // Ensure we have https:// prefix for GitHub domains
        if normalized.hasPrefix("https://github.com/") {
            return normalized
        }
        
        if normalized.hasPrefix("github.com/") {
            return "https://\(normalized)"
        }
        
        // Fallback: if it already looks like https and isn't GitHub specific, return as-is
        if normalized.hasPrefix("http://") || normalized.hasPrefix("https://") {
            return normalized
        }
        
        return trimmed
    }
}
