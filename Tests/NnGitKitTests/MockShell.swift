//
//  MockShell.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import Foundation
@testable import GitShellKit

final class MockShell {
    private let throwError: Bool
    private var runResults: [String]
    private(set) var commands: [String] = []
    
    init(runResults: [String] = [], throwError: Bool) {
        self.runResults = runResults
        self.throwError = throwError
    }
}


// MARK: - Shell
extension MockShell: GitShell {
    func runWithOutput(_ command: String) throws -> String {
        commands.append(command)
        if throwError { throw NSError(domain: "Test", code: 0) }
        
        
        return runResults.isEmpty ? "" : runResults.removeFirst()
    }
}
