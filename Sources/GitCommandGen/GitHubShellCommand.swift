//
//  GitHubShellCommand.swift
//  GitCommandGen
//
//  Created by Nikolai Nobadi on 3/20/25.
//

public enum GitHubShellCommand {
    case getLatestReleaseAssetURL
    case getPreviousReleaseVersion
    case createRemoteRepo(name: String, visibility: String, details: String)
    case createNewReleaseWithBinary(version: String, binaryPath: String, releaseNotes: String)
}


// MARK: - Arg
public extension GitHubShellCommand {
    var arg: String {
        switch self {
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
