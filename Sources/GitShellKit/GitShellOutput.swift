//
//  GitShellOutput.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import Foundation

/// Helpers that centralize parsing assumptions for Git and GitHub CLI output.
internal enum GitShellOutput {
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
    
    /// Parses the output of `git remote` into a list of remote names.
    static func parseRemotes(_ output: String) -> [String] {
        output
            .split(separator: "\n")
            .map(String.init)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    /// Parses the output of `git symbolic-ref refs/remotes/origin/HEAD` to extract the default branch.
    static func parseRemoteDefaultBranch(_ output: String) -> String? {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("refs/remotes/origin/") else { return nil }
        
        let branch = String(trimmed.dropFirst("refs/remotes/origin/".count))
        return branch.isEmpty ? nil : branch
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

    /// Parses the output of `git branch --list` into an array of branch names.
    static func parseBranchList(_ output: String) -> [String] {
        output
            .split(separator: "\n")
            .map(String.init)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { $0.hasPrefix("* ") ? String($0.dropFirst(2)) : $0 }
    }

    /// Parses the output of `git branch -r` into an array of remote branch names without the `origin/` prefix.
    static func parseRemoteBranchList(_ output: String) -> [String] {
        output
            .split(separator: "\n")
            .map(String.init)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { !$0.contains("HEAD ->") }
            .map { $0.hasPrefix("origin/") ? String($0.dropFirst("origin/".count)) : $0 }
    }

    /// Parses the output of `git status --porcelain` into an array of change lines.
    static func parseLocalChanges(_ output: String) -> [String] {
        output
            .split(separator: "\n")
            .map(String.init)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Parses a date string from git log `--date=iso-local` format.
    static func parseBranchCreationDate(_ output: String) -> Date? {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: trimmed)
    }

    /// Parses the tab-separated output of `git rev-list --left-right --count` into a `BranchSyncStatus`.
    static func parseSyncStatus(_ output: String) -> BranchSyncStatus {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: "\t")
        guard parts.count == 2,
              let ahead = Int(parts[0]),
              let behind = Int(parts[1]) else {
            return .undetermined
        }

        switch (ahead, behind) {
        case (0, 0):
            return .nsync
        case (let a, 0):
            return .ahead(a)
        case (0, let b):
            return .behind(b)
        default:
            return .diverged(ahead: ahead, behind: behind)
        }
    }
}
