//
//  ReleaseNoteInfo.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 3/24/25.
//

public struct ReleaseNoteInfo {
    public let content: String
    public let isFromFile: Bool
    
    public init(content: String, isFromFile: Bool) {
        self.content = content
        self.isFromFile = isFromFile
    }
}


// MARK: - Arg
extension ReleaseNoteInfo {
    var arg: String {
        return "--notes\(isFromFile ? "-file" : "") \(content)"
    }
}
