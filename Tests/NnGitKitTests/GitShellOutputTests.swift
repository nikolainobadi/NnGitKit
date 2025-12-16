//
//  GitShellOutputTests.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import Testing
@testable import GitShellKit

struct GitShellOutputTests { 
    @Test("Determines truthy output using trimming")
    func isTrueParsesTrimmedOutput() {
        #expect(GitShellOutput.isTrue("true"))
        #expect(GitShellOutput.isTrue(" true\n"))
        #expect(GitShellOutput.isTrue("\ntrue\t"))
    }
    
    @Test("Returns false for non-true output")
    func isTrueRejectsNonTrueOutput() {
        #expect(!GitShellOutput.isTrue("false"))
        #expect(!GitShellOutput.isTrue(" true value "))
        #expect(!GitShellOutput.isTrue("TRUE"))
        #expect(!GitShellOutput.isTrue(""))
    }
    
    @Test("Detects origin remote in newline-delimited output")
    func containsOriginRemoteMatchesLines() {
        let singleLine = "origin"
        let multiLine = "upstream\norigin\nfork"
        let withWhitespace = "\n origin\n"
        
        #expect(GitShellOutput.containsOriginRemote(singleLine))
        #expect(GitShellOutput.containsOriginRemote(multiLine))
        #expect(GitShellOutput.containsOriginRemote(withWhitespace))
    }
    
    @Test("Returns false when origin remote is absent")
    func containsOriginRemoteReturnsFalse() {
        #expect(!GitShellOutput.containsOriginRemote("upstream"))
        #expect(!GitShellOutput.containsOriginRemote("origin-remote"))
        #expect(!GitShellOutput.containsOriginRemote(""))
    }
}
