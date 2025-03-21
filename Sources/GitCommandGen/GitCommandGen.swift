//
//  GitCommandGen.swift
//  GitCommandGen
//
//  Created by Nikolai Nobadi on 3/20/25.
//

public func makeGitCommand(_ command: GitShellCommand, path: String?) -> String {
    if let path {
        return "git -C \"\(path)\" \(command.arg)"
    }
    
    return "git \(command.arg)"
}


public func makeGitHubCommand(_ command: GitHubShellCommand, path: String?) -> String {
    if let path {
        return "cd \"\(path)\" && \(command.arg)"
    }
    return command.arg
}

