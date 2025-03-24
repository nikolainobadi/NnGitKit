//
//  GitCommandGen.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 3/20/25.
//

/// Creates a Git command string with an optional working directory path.
///
/// - Parameters:
///   - command: The `GitShellCommand` to execute.
///   - path: An optional file system path to execute the command in.
/// - Returns: A formatted Git command string.
public func makeGitCommand(_ command: GitShellCommand, path: String?) -> String {
    if let path {
        return "git -C \"\(path)\" \(command.arg)"
    }
    return "git \(command.arg)"
}

/// Creates a GitHub command string with an optional working directory path.
///
/// - Parameters:
///   - command: The `GitHubShellCommand` to execute.
///   - path: An optional file system path to execute the command in.
/// - Returns: A formatted GitHub command string.
public func makeGitHubCommand(_ command: GitHubShellCommand, path: String?) -> String {
    if let path {
        return """
        cd \"\(path)\" && \(command.arg)
        """
    }
    
    return command.arg
}

