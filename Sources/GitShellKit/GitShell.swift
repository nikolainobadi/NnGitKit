//
//  GitShell.swift
//  GitCommandGen
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import GitCommandGen

public protocol GitShell {
    @discardableResult
    func runWithOutput(_ command: String) throws -> String
}


// MARK: - Helper Methods
public extension GitShell {
    func getGitHubURL(at path: String?) throws -> String {
        return try runWithOutput(makeGitCommand(.getRemoteURL, path: path)).toGitHubURL()
    }
    
    func localGitExists(at path: String?) throws -> Bool {
        return try runWithOutput(makeGitCommand(.localGitCheck, path: path)) == "true"
    }
    
    func remoteExists(path: String?) throws -> Bool {
        let output = try runWithOutput(makeGitCommand(.checkForRemote, path: path))
        let remotes = output.split(separator: "\n").map(String.init)
        
        return remotes.contains("origin")
    }
}


// MARK: - Extension Dependencies
public extension String {
    func toGitHubURL() -> String {
        return self
            .replacingOccurrences(of: "com:", with: "com/")
            .replacingOccurrences(of: "git@", with: "https://")
            .replacingOccurrences(of: ".git", with: "")
    }
}
