//
//  GitShellError.swift
//  GitCommandGen
//
//  Created by Nikolai Nobadi on 3/21/25.
//

public enum GitShellError: Error {
    case missingLocalGit
    case localGitAlreadyExists
    case remoteRepoAlreadyExists
}
