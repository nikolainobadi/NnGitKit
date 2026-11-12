# NnGitKit Testing Reference

Test doubles for code built on `GitClient` and `GitHubClient`. Import `NnGitTesting`. It re-exports NnGitKit (`@_exported import NnGitKit`), so a separate `import NnGitKit` is optional in test files.

Add the product to your test target:

```swift
.testTarget(name: "MyToolTests", dependencies: ["MyTool", .product(name: "NnGitTesting", package: "NnGitKit")])
```

---

<!-- type:MockGitCommandRunner -->
## Struct: MockGitCommandRunner

A `GitCommandRunner` that returns scripted outputs.

```swift
public struct MockGitCommandRunner: GitCommandRunner {
    public init(gitResults: [GitResult], gitHubResults: [GitHubResult])

    public struct GitResult: Sendable {
        public init(command: GitCommand, path: String, output: GitCommandOutput)
    }

    public struct GitHubResult: Sendable {
        public init(command: GitHubCommand, path: String?, output: GitCommandOutput)
    }

    public enum UnexpectedCommand: Error, Equatable {
        case git(command: GitCommand, path: String)
        case gitHub(command: GitHubCommand, path: String?)
    }
}
```

### Matching Rules

- A result matches when **both** `command == ` and `path == ` hold. `GitCommand` equality includes associated values, so `.commit(message: "a")` doesn't match `.commit(message: "b")`.
- The **first** matching result wins, **every time**. There's no queue, so the same command at the same path can't return different outputs on successive calls.
- An unmatched command **throws** `UnexpectedCommand` instead of returning empty output. An empty string looks like a real answer, so comparisons between two unscripted commands would silently pass.
- GitHub results usually need `path: nil`. Only `repositoryOwner(at:)`, `repositoryNameWithOwner(at:)`, `createRelease(tag:title:notesFilePath:at:)`, and `createPullRequest(base:head:in:at:)` pass a path (see the Command (path) column in ApiReference.md).
- Script failures by setting a non-zero `exitCode`, for example `GitCommandOutput(exitCode: 1, output: "")` for `isIgnored → false`, or `output: "gh: Not Found (HTTP 404)"` for a GitHub 404.
<!-- /type:MockGitCommandRunner -->

---

<!-- type:RecordingGitCommandRunner -->
## Class: RecordingGitCommandRunner

Wraps a `MockGitCommandRunner` and records every call in order, **including unscripted calls that then throw**. It's a `final class` whose state is guarded by a `Mutex`, so share one instance between the SUT and the test.

```swift
public final class RecordingGitCommandRunner: GitCommandRunner {
    public init(gitResults: [MockGitCommandRunner.GitResult], gitHubResults: [MockGitCommandRunner.GitHubResult])

    public var gitCalls: [GitCall] { get }          // command + path
    public var gitHubCalls: [GitHubCall] { get }    // command + optional path
    public var gitCommands: [GitCommand] { get }    // commands only
    public var gitHubCommands: [GitHubCommand] { get }

    public struct GitCall: Sendable, Equatable { public let command: GitCommand; public let path: String }
    public struct GitHubCall: Sendable, Equatable { public let command: GitHubCommand; public let path: String? }
}
```

Use `gitCommands` to assert the sequence, and `gitCalls` when the path matters too (for example, worktree code that runs in several directories).
<!-- /type:RecordingGitCommandRunner -->

---

## Complete Example

Code under test:

```swift
import NnGitKit

struct Committer {
    let git: GitClient

    /// Commits everything when the repo is dirty. Returns whether a commit was made.
    func commitIfDirty(message: String, at path: String) throws -> Bool {
        guard try git.hasUncommittedChanges(at: path) else {
            return false
        }

        try git.stageAll(at: path)
        try git.commit(message: message, at: path)

        return true
    }
}
```

Tests:

```swift
import Testing
import NnGitTesting
@testable import MyTool

struct CommitterTests {
    @Test
    func `A dirty repo is staged and committed`() throws {
        let (sut, runner) = makeSUT(gitResults: [
            result(.statusPorcelain, exitCode: 0, output: " M README.md"),
            result(.addAll, exitCode: 0, output: ""),
            result(.commit(message: "Update"), exitCode: 0, output: "")
        ])

        #expect(try sut.commitIfDirty(message: "Update", at: repo))
        #expect(runner.gitCommands == [.statusPorcelain, .addAll, .commit(message: "Update")])
    }

    @Test
    func `A clean repo runs nothing after the status check`() throws {
        let (sut, runner) = makeSUT(gitResults: [result(.statusPorcelain, exitCode: 0, output: "")])

        #expect(try sut.commitIfDirty(message: "Update", at: repo) == false)
        #expect(runner.gitCommands == [.statusPorcelain])
    }

    @Test
    func `A failed commit surfaces as a GitError`() {
        let (sut, _) = makeSUT(gitResults: [
            result(.statusPorcelain, exitCode: 0, output: " M README.md"),
            result(.addAll, exitCode: 0, output: ""),
            result(.commit(message: "Update"), exitCode: 1, output: "nothing to commit")
        ])

        // GitError is not Equatable: match the type (or pattern-match the case).
        #expect(throws: GitError.self) {
            try sut.commitIfDirty(message: "Update", at: repo)
        }
    }
}

// MARK: - Helpers
private extension CommitterTests {
    var repo: String { "/repo" }

    func result(_ command: GitCommand, exitCode: Int32, output: String) -> MockGitCommandRunner.GitResult {
        return .init(command: command, path: repo, output: .init(exitCode: exitCode, output: output))
    }
}

// MARK: - SUT
private extension CommitterTests {
    func makeSUT(gitResults: [MockGitCommandRunner.GitResult]) -> (sut: Committer, runner: RecordingGitCommandRunner) {
        let runner = RecordingGitCommandRunner(gitResults: gitResults, gitHubResults: [])

        return (Committer(git: GitClient(runner: runner)), runner)
    }
}
```

GitHub example, a 404 that becomes `false`:

```swift
let runner = RecordingGitCommandRunner(gitResults: [], gitHubResults: [
    .init(command: .apiRead(endpoint: "repos/me/app", jq: ".full_name"), path: nil,
          output: .init(exitCode: 1, output: "gh: Not Found (HTTP 404)"))
])

#expect(try GitHubClient(runner: runner).repoExists("me/app") == false)
#expect(runner.gitHubCommands == [.apiRead(endpoint: "repos/me/app", jq: ".full_name")])
```

---

## Scripting Raw Output

Scripted output must look like what the real command prints, because the client parses it.

| Client method | Script this command | Output shape |
|---------------|---------------------|--------------|
| `localBranches` | `.localBranchDetails` | One line per branch: `name\0worktreePath\0upstream\0track`, where track is like `ahead 2, behind 1` or `gone` |
| `upstream(of:)` | `.upstreamDetails(branch:)` | `origin/x\0origin\0refs/heads/x\0[gone]`. The first field is empty when there's no upstream |
| `worktrees` | `.worktreeList` | NUL-separated fields, with an empty field between records: `worktree /p\0HEAD <sha>\0branch refs/heads/main\0\0worktree /q\0detached\0locked reason\0` |
| `uncommittedFiles` | `.statusPorcelainCollapsed` | Porcelain v2 `-z` entries: `1 .M N... 100644 100644 100644 <h> <h> path\0`, `? path\0`. A rename is `2 R. ... new\0old\0` |
| `uncommittedPaths`, `untrackedPaths`, `uncommittedFileCounts` | `.statusPorcelainPaths` | Same porcelain v2 format |
| `recentCommits` | `.logFirstParent(limit:)` | Records ending in `\u{1e}`: `sha\0short\0subject\0name\0email\0reldate\0parents`. Exactly 7 fields, otherwise `unreadableOutput` |
| `commitActivity` | `.logActivity(refs:since:author:)` | `\u{1e}short\0YYYY-MM-DD` then `added\tdeleted\tpath` numstat lines (`-` for binary) |
| `commitChanges` | `.logCommitChanges(range:)` | `\u{1e}short\0date\0subject`, numstat lines, then ` create mode 100644 path` / ` delete mode ...` summary lines |
| `commitMessages` | `.logMessages(since:paths:)` | Bodies separated by `\u{1e}` |
| `trackedPaths`, `ignoredTrackedPaths`, `pathsRestoredByReset`, `unversionedPaths` | their `ls-files`/`diff` command | NUL-separated paths |
| `pullRequest(number:in:)` | `.pullRequestDetails(repo:number:)` | `branch\tOPEN\tfalse` |
| `contentMergedBranches` | `.revParseTree(ref:)` + `.mergeTreeWriteTree(base:branch:)` per branch | The tree sha. A branch is merged when the first line of merge-tree output equals it |

## Tips

- **`UnexpectedCommand` in a test** means the code ran a command or path you didn't script. Check `runner.gitCalls` to see the exact case and path, including associated values such as `.revParseCommit(ref: "refs/heads/main")`.
- **Lookups that wrap refs:** `commit(of: "main")` runs `.revParseCommit(ref: "refs/heads/main")`, `commit(ofTag: "v1")` runs `.revParseCommit(ref: "refs/tags/v1")`, and `remoteHeadBranches(for: ["origin"])` runs `.symbolicRefShort(ref: "refs/remotes/origin/HEAD")`.
- **Need different outputs for the same command?** The mock can't do that. Restructure the test, or write a small custom `GitCommandRunner` for that case.
- **Test your runner separately.** `CommandArgumentsTests`-style tests can assert `command.arguments(at:)` / `command.arguments` when you need to check the exact argv.
