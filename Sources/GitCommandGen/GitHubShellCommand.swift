//
//  GitHubShellCommand.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 3/20/25.
//

/// Represents GitHub shell commands that can be executed using the GitHub CLI (gh).
public enum GitHubShellCommand {
    /// Retrieves the GitHub username of the authenticated user.
    case getGithubUsername

    /// Retrieves the URL of the latest release asset.
    case getLatestReleaseAssetURL

    /// Retrieves the version of the previous release.
    case getPreviousReleaseVersion

    /// Creates a new remote repository with the specified name, visibility, and details.
    ///
    /// - Parameters:
    ///   - name: The name of the repository to create.
    ///   - visibility: The visibility of the repository (e.g., "public" or "private").
    ///   - details: A brief description of the repository.
    case createRemoteRepo(name: String, visibility: String, details: String)

    /// Creates a new release with the specified version, binary path, and release notes.
    ///
    /// - Parameters:
    ///   - version: The version tag for the release.
    ///   - binaryPath: The path to the binary to include in the release.
    ///   - releaseNotes: The notes to include with the release.
    case createNewReleaseWithBinary(version: String, binaryPath: String, releaseNotes: String)
}

// MARK: - Arg
public extension GitHubShellCommand {
    /// The shell argument string corresponding to the GitHub shell command.
    var arg: String {
        switch self {
        case .getGithubUsername:
            return "gh api user --jq '.login'"
        case .getLatestReleaseAssetURL:
            return "gh release view --json assets -q '.assets[].url'"
        case .getPreviousReleaseVersion:
            return "gh release view --json tagName -q '.tagName'"
        case .createRemoteRepo(let name, let visibility, let details):
            return "gh repo create \(name) --\(visibility) -d '\(details)'"
        case .createNewReleaseWithBinary(let version, let binaryPath, let releaseNotes):
            return """
            gh release create \(version) \(binaryPath) --title "\(version)" --notes "\(releaseNotes)"
            """
        }
    }
}
