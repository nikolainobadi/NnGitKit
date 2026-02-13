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

    /// Creates a new release with the specified version, binary paths, and release notes.
    ///
    /// - Parameters:
    ///   - version: The version tag for the release.
    ///   - binaryPaths: The paths to the binaries to include in the release.
    ///   - noteSource: The source of the release notes.
    case createNewRelease(version: String, binaryPaths: [String], noteSource: ReleaseNoteSource)
    
    /// Retrieves the asset URLs for a specific release version.
    ///
    /// - Parameter version: The version tag to query.
    case getReleaseAssetURLs(version: String)

    /// Checks the authentication status for the GitHub CLI.
    case authStatus
    
    /// Checks that the GitHub CLI is available on the system.
    case version
}

// MARK: - Arg
public extension GitHubShellCommand {
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
        case .createNewRelease(let version, let binaryPaths, let noteSource):
            let paths = binaryPaths.joined(separator: " ")
            return """
            gh release create \(version) \(paths) --title "\(version)" \(noteSource.arg)
            """
        case .getReleaseAssetURLs(let version):
            return "gh release view \(version) --json assets -q '.assets[].url'"
        case .authStatus:
            return "gh auth status"
        case .version:
            return "gh --version"
        }
    }
}
