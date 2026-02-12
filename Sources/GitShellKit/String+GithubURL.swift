//
//  String+GithubURL.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 12/16/25.
//

public extension String {
    /// Converts a Git SSH URL to an HTTPS URL.
    ///
    /// - Returns: A formatted HTTPS URL for the GitHub repository.
    func toGitHubURL() -> String {
        return GitShellOutput.normalizeGitHubURL(self)
    }
}
