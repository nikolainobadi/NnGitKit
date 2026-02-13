//
//  ErrorTests.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 2/12/26.
//

import Testing
@testable import GitShellKit

struct GitShellErrorTests {
    @Test("All GitShellError cases have non-nil, non-empty errorDescription")
    func allCasesHaveDescription() {
        let allCases: [GitShellError] = [
            .missingLocalGit,
            .localGitAlreadyExists,
            .remoteRepoAlreadyExists,
            .currentBranchIsNotMainBranch,
            .githubCLINotAvailable,
            .githubCLINotAuthenticated,
            .remoteCreatedFollowupFailed,
        ]

        for error in allCases {
            let description = error.errorDescription
            #expect(description != nil)
            #expect(description?.isEmpty == false)
        }
    }

    @Test("missingLocalGit has expected description")
    func missingLocalGitDescription() {
        #expect(GitShellError.missingLocalGit.errorDescription == "No local Git repository found.")
    }

    @Test("githubCLINotAvailable has expected description")
    func githubCLINotAvailableDescription() {
        #expect(GitShellError.githubCLINotAvailable.errorDescription == "The GitHub CLI (gh) is not installed or not available on PATH.")
    }
}


struct GitCommandFailureTests {
    @Test("errorDescription includes the command string")
    func errorDescriptionIncludesCommand() {
        let error = GitCommandFailure(command: "git push", output: "rejected")
        #expect(error.errorDescription == "Git command failed: git push")
    }

    @Test("failureReason returns the output")
    func failureReasonReturnsOutput() {
        let error = GitCommandFailure(command: "git push", output: "rejected by remote")
        #expect(error.failureReason == "rejected by remote")
    }
}
