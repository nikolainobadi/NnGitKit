# NnGitKit

![CI](https://github.com/nikolainobadi/NnGitKit/actions/workflows/ci.yml/badge.svg)
![Swift Version](https://badgen.net/badge/swift/6.4%2B/purple)
![Platform](https://img.shields.io/badge/Platform-macOS%2015%2B-lightgrey)
![SPM](https://img.shields.io/badge/Distribution-SPM%20only-red)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

NnGitKit is a Swift package for working with Git and the GitHub CLI (`gh`) from Swift. It models every `git` and `gh` invocation as a typed command, and exposes high-level clients (`GitClient`, `GitHubClient`) that run those commands and parse their output into Swift values.

NnGitKit never launches processes itself. You supply a `GitCommandRunner`, so the package works with any process or shell library.

> **Upgrading from 0.x:** 1.0.0 replaces the old `GitShellKit` / `GitCommandGen` API entirely. If you depend on it, stay pinned to `0.6.x`.

## Features

- Typed `GitCommand` and `GitHubCommand` enums. Every value is passed as its own argument, never interpolated into shell text
- `GitClient`: status, branches, commits, remotes, tracking, tags, worktrees, discard/reset, merged-branch detection, commit activity
- `GitHubClient`: auth, repos, pull requests, releases
- Default-branch detection helpers
- `NnGitTesting` library with `MockGitCommandRunner` and `RecordingGitCommandRunner` for tests
- No dependencies

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/nikolainobadi/NnGitKit.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "NnGitKit", package: "NnGitKit")
        ]
    ),
    .testTarget(
        name: "YourAppTests",
        dependencies: [
            .product(name: "NnGitTesting", package: "NnGitKit")
        ]
    )
]
```

## Usage

### 1. Provide a runner

A `GitCommandRunner` turns a command into a process run and reports the exit code and output. A non-zero exit code is returned, not thrown: the clients decide what a failure means.

```swift
import Foundation
import NnGitKit

struct ProcessGitRunner: GitCommandRunner {
    func runGit(_ command: GitCommand, at path: String) throws -> GitCommandOutput {
        // arguments(at:) already includes `-C <path>`
        return try run("/usr/bin/git", args: command.arguments(at: path), directory: nil)
    }

    func runGitHub(_ command: GitHubCommand, at path: String?) throws -> GitCommandOutput {
        // gh reads the repository from its working directory
        return try run("/usr/bin/env", args: ["gh"] + command.arguments, directory: path)
    }

    private func run(_ program: String, args: [String], directory: String?) throws -> GitCommandOutput {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: program)
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = pipe

        if let directory {
            process.currentDirectoryURL = URL(fileURLWithPath: directory)
        }

        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        return GitCommandOutput(exitCode: process.terminationStatus, output: String(decoding: data, as: UTF8.self))
    }
}
```

### 2. Use the clients

```swift
let git = GitClient(runner: ProcessGitRunner())
let path = "/path/to/project"

let branch = try git.currentBranch(at: path)
let isDirty = try git.hasUncommittedChanges(at: path)
let recent = try git.recentCommits(limit: 5, at: path)

try git.stageAll(at: path)
try git.commit(message: "Initial commit", at: path)
try git.pushBranchSettingUpstream("main", to: "origin", at: path)
```

```swift
let gitHub = GitHubClient(runner: ProcessGitRunner())

guard try gitHub.isAuthenticated() else {
    fatalError("Run `gh auth login` first")
}

try gitHub.createRepo(
    "username/MyRepo",
    visibility: .private,
    description: "An awesome repo",
    sourcePath: "/path/to/project",
    remote: "origin"
)
```

### Errors

Failed commands throw `GitError` or `GitHubError`. Both conform to `LocalizedError`, and their messages include the full command and its output.

## Testing

`NnGitTesting` provides runners that return scripted results:

```swift
import Testing
import NnGitTesting

@Test func readsCurrentBranch() throws {
    let runner = RecordingGitCommandRunner(
        gitResults: [
            .init(command: .branchShowCurrent, path: "/repo", output: .init(exitCode: 0, output: "main\n"))
        ],
        gitHubResults: []
    )
    let git = GitClient(runner: runner)

    #expect(try git.currentBranch(at: "/repo") == "main")
    #expect(runner.gitCommands == [.branchShowCurrent])
}
```

`MockGitCommandRunner` throws `UnexpectedCommand` for any command it has no result for. An empty string looks like a real answer, so missing results never pass silently.

## Contributing

Feel free to submit issues or pull requests. If you have ideas for new commands or improvements, I’d love to hear from you!

## License

NnGitKit is available under the MIT license. See the [LICENSE](LICENSE) file for more information.
