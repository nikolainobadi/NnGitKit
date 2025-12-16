//
//  ReleaseNoteSource.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 12/16/25.
//

public enum ReleaseNoteSource {
    case exact(String)
    case filePath(String)
}


// MARK: - Arg
extension ReleaseNoteSource {
    var arg: String {
        switch self {
        case .exact(let notes):
            return "--notes \"\(notes)\""
        case .filePath(let filePath):
            return "--notes-file \"\(filePath)\""
        }
    }
}
