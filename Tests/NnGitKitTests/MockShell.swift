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
    private let errorIndices: Set<Int>
    private var runResults: [String]
    private(set) var commands: [String] = []
    
    init(runResults: [String] = [], throwError: Bool = false, errorIndices: Set<Int> = []) {
        self.runResults = runResults
        self.throwError = throwError
        self.errorIndices = errorIndices
    }
}


// MARK: - Shell
extension MockShell: GitShell {
    func runWithOutput(_ command: String) throws -> String {
        commands.append(command)
        if throwError || errorIndices.contains(commands.count - 1) {
            throw GitCommandFailure(command: command, output: "error-\(commands.count - 1)")
        }
        
        
        return runResults.isEmpty ? "" : runResults.removeFirst()
    }
    
    func runAndPrint(_ command: String) throws {
        commands.append(command)
        if throwError || errorIndices.contains(commands.count - 1) {
            throw GitCommandFailure(command: command, output: "error-\(commands.count - 1)")
        }
        
        if !runResults.isEmpty {
            _ = runResults.removeFirst()
        }
    }
}
