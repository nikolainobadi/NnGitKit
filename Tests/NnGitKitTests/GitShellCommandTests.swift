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

    @Test("addAll produces 'add --all' arg string")
    func addAllArg() {
        let command = GitShellCommand.addAll
        #expect(command.arg == "add --all")
    }

    // MARK: - Merge & Stash
    @Test("merge produces correct arg string")
    func mergeArg() {
        let command = GitShellCommand.merge(branch: "feature/login")
        #expect(command.arg == "merge feature/login")
    }

    @Test("stash produces correct arg string")
    func stashArg() {
        let command = GitShellCommand.stash
        #expect(command.arg == "stash")
    }

    @Test("stashPop produces correct arg string")
    func stashPopArg() {
        let command = GitShellCommand.stashPop
        #expect(command.arg == "stash pop")
    }

    // MARK: - Diff
    @Test("diff produces correct arg string")
    func diffArg() {
        let command = GitShellCommand.diff
        #expect(command.arg == "diff")
    }

    @Test("diffStaged produces correct arg string")
    func diffStagedArg() {
        let command = GitShellCommand.diffStaged
        #expect(command.arg == "diff --staged")
    }

    // MARK: - Tags
    @Test("tag produces correct arg string")
    func tagArg() {
        let command = GitShellCommand.tag(name: "v1.0.0", message: "Release 1.0.0")
        #expect(command.arg == "tag -a v1.0.0 -m \"Release 1.0.0\"")
    }

    @Test("listTags produces correct arg string")
    func listTagsArg() {
        let command = GitShellCommand.listTags
        #expect(command.arg == "tag -l")
    }
}


// MARK: - GitHub Shell Command Tests
struct GitHubShellCommandTests {
    @Test("createNewRelease with single binary path produces correct arg")
    func createNewReleaseSingleBinary() {
        let command = GitHubShellCommand.createNewRelease(
            version: "v1.0.0",
            binaryPaths: ["/path/to/binary"],
            noteSource: .exact("Initial release")
        )
        #expect(command.arg == "gh release create v1.0.0 /path/to/binary --title \"v1.0.0\" --notes \"Initial release\"")
    }

    @Test("createNewRelease with multiple binary paths produces space-separated arg")
    func createNewReleaseMultipleBinaries() {
        let command = GitHubShellCommand.createNewRelease(
            version: "v2.0.0",
            binaryPaths: ["/path/to/binary1", "/path/to/binary2", "/path/to/binary3"],
            noteSource: .filePath("/notes.md")
        )
        #expect(command.arg == "gh release create v2.0.0 /path/to/binary1 /path/to/binary2 /path/to/binary3 --title \"v2.0.0\" --notes-file \"/notes.md\"")
    }

    @Test("getReleaseAssetURLs produces correct arg string")
    func getReleaseAssetURLsArg() {
        let command = GitHubShellCommand.getReleaseAssetURLs(version: "v1.2.3")
        #expect(command.arg == "gh release view v1.2.3 --json assets -q '.assets[].url'")
    }
}
