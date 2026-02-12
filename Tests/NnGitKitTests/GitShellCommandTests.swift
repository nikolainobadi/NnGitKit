//
//  GitShellCommandTests.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 2/12/26.
//

import Testing
@testable import GitCommandGen

struct GitShellCommandTests {
    @Test("getConfig produces correct arg string")
    func getConfigArg() {
        let command = GitShellCommand.getConfig(key: "user.email")
        #expect(command.arg == "config --get user.email")
    }

    @Test("checkoutTracking produces correct arg string")
    func checkoutTrackingArg() {
        let command = GitShellCommand.checkoutTracking(local: "feature", remote: "origin/feature")
        #expect(command.arg == "checkout -b feature origin/feature")
    }

    @Test("listTrackedFiles produces correct arg string")
    func listTrackedFilesArg() {
        let command = GitShellCommand.listTrackedFiles
        #expect(command.arg == "ls-files")
    }

    @Test("untrackFile produces correct arg string")
    func untrackFileArg() {
        let command = GitShellCommand.untrackFile(path: "secrets.txt")
        #expect(command.arg == "rm --cached secrets.txt")
    }

    @Test("softReset produces correct arg string")
    func softResetArg() {
        let command = GitShellCommand.softReset(count: 3)
        #expect(command.arg == "reset --soft HEAD~3")
    }

    @Test("hardReset produces correct arg string")
    func hardResetArg() {
        let command = GitShellCommand.hardReset(count: 1)
        #expect(command.arg == "reset --hard HEAD~1")
    }

    @Test("log produces correct arg string")
    func logArg() {
        let command = GitShellCommand.log(count: 5, format: "%H %s")
        #expect(command.arg == "log -n 5 --pretty=format:\"%H %s\"")
    }

    @Test("makeGitCommand wraps with path correctly")
    func makeGitCommandWithPath() {
        let result = makeGitCommand(.getConfig(key: "user.name"), path: "/my/repo")
        #expect(result == "git -C \"/my/repo\" config --get user.name")
    }

    @Test("makeGitCommand without path omits -C flag")
    func makeGitCommandWithoutPath() {
        let result = makeGitCommand(.listTrackedFiles, path: nil)
        #expect(result == "git ls-files")
    }
}
