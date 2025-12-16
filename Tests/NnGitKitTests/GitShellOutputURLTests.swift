//
//  GitShellOutputURLTests.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import Testing
@testable import GitShellKit

struct GitShellOutputURLTests { }


// MARK: - Unit Tests
extension GitShellOutputURLTests {
    @Test("Normalizes SSH style GitHub URLs to https")
    func normalizesSSHURLs() {
        #expect(GitShellOutput.normalizeGitHubURL("git@github.com:user/repo.git") == "https://github.com/user/repo")
        #expect(GitShellOutput.normalizeGitHubURL("git@github.com:user/repo") == "https://github.com/user/repo")
    }
    
    @Test("Normalizes https GitHub URLs by stripping .git")
    func normalizesHTTPSURLs() {
        #expect(GitShellOutput.normalizeGitHubURL("https://github.com/user/repo.git") == "https://github.com/user/repo")
        #expect(GitShellOutput.normalizeGitHubURL("https://github.com/user/repo") == "https://github.com/user/repo")
    }
    
    @Test("Handles github.com prefixes without protocol")
    func normalizesBareDomainURLs() {
        #expect(GitShellOutput.normalizeGitHubURL("github.com:user/repo.git") == "https://github.com/user/repo")
        #expect(GitShellOutput.normalizeGitHubURL("github.com/user/repo") == "https://github.com/user/repo")
    }
    
    @Test("Returns unchanged string when normalization fails or not applicable")
    func returnsOriginalForUnsupported() {
        #expect(GitShellOutput.normalizeGitHubURL("git@gitlab.com:user/repo.git") == "git@gitlab.com:user/repo.git")
        #expect(GitShellOutput.normalizeGitHubURL("") == "")
    }
}
