# NnGitKit API Reference

Typed `git`/`gh` commands, a runner protocol, and clients that run and parse them. Import `NnGitKit`.

**Contents**
- Protocol: GitCommandRunner (Contract, Example runner)
- Struct: GitClient: Repository & Status · Branches · Commits & Index · Discard & Reset · Tracking · Remotes, Fetch & Push · Worktrees · Tags, Config, Init
- Struct: GitHubClient: Auth & Repos · Pull Requests · Releases
- Value Types
- Enum: GitError · Enum: GitHubError
- Default-Branch Helpers (Typical composition)
- Best Practices

**Conventions used in the method tables**
- **Command** is the `GitCommand`/`GitHubCommand` case the method runs. Tests must script exactly this case (see TestingReference.md).
- **Non-zero exit** describes what happens when the runner reports a non-zero exit code. "throws" means `GitError.commandFailed` (or `GitHubError.commandFailed` for gh).
- Successful output is trimmed of surrounding whitespace and newlines unless noted.
- Errors thrown by the runner itself (for example, a launch failure) always propagate unchanged.

---

<!-- type:GitCommandRunner -->
## Protocol: GitCommandRunner

The single seam between NnGitKit and process execution. The package never launches processes itself.

```swift
public protocol GitCommandRunner: Sendable {
    func runGit(_ command: GitCommand, at path: String) throws -> GitCommandOutput
    func runGitHub(_ command: GitHubCommand, at path: String?) throws -> GitCommandOutput
}

public struct GitCommandOutput: Sendable, Equatable {
    public let exitCode: Int32
    public let output: String
    public init(exitCode: Int32, output: String)
}
```

### Contract

| Requirement | Detail |
|-------------|--------|
| git arguments | Run `git` with `command.arguments(at: path)`, which is `["-C", path] + <subcommand args>` |
| gh arguments | Run `gh` with `command.arguments`. Use `path` (when non-nil) as the process working directory, because gh has no `-C` |
| Non-zero exit | **Return** `GitCommandOutput(exitCode:output:)`. Don't throw. Clients rely on exit codes as answers |
| Output | Return combined stdout and stderr. Several clients search failure output (for example, gh's `(HTTP 404)`) |
| Throwing | Only for failures to run at all (missing executable, launch error) |
| No shell | Pass the argument array straight to the executable. Never join it into a shell string |

### Example runner (Foundation)

```swift
import Foundation
import NnGitKit

struct ProcessGitRunner: GitCommandRunner {
    func runGit(_ command: GitCommand, at path: String) throws -> GitCommandOutput {
        return try run(["git"] + command.arguments(at: path), in: nil)
    }

    func runGitHub(_ command: GitHubCommand, at path: String?) throws -> GitCommandOutput {
        return try run(["gh"] + command.arguments, in: path)
    }

    private func run(_ arguments: [String], in directory: String?) throws -> GitCommandOutput {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
        process.currentDirectoryURL = directory.map { URL(fileURLWithPath: $0) }
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        return GitCommandOutput(exitCode: process.terminationStatus, output: String(decoding: data, as: UTF8.self))
    }
}
```

`GitCommand` has 74 cases and `GitHubCommand` has 17. You rarely build them by hand. The clients choose them. Both are `Equatable` and `Sendable`. `GitCommand.arguments(at:)` and `GitHubCommand.arguments` are the only public members.
<!-- /type:GitCommandRunner -->

---

<!-- type:GitClient -->
## Struct: GitClient

```swift
public struct GitClient: Sendable {
    public init(runner: any GitCommandRunner)
}
```

Every method below `throws` and takes `at path: String`, the repository (or any directory inside it). The exceptions are the worktree add/remove methods, which take `in path:` (see Worktrees).

### Repository & Status

| Method | Returns | Command | Non-zero exit |
|--------|---------|---------|---------------|
| `repositoryRoot(at:)` | `String?` | `.revParseTopLevel` | `nil` |
| `repositoryRootLookup(at:)` | `RepositoryRootLookup` | `.revParseTopLevel` | `.notFound(output:)` with trimmed output |
| `gitDirectory(at:)` | `String` | `.revParseAbsoluteGitDir` | throws |
| `headCommit(at:)` | `String?` (full sha) | `.revParseHead` | `nil` (e.g. no commits yet) |
| `commit(ofRevision:at:)` | `String?` | `.revParseCommit(ref: revision)` | `nil`. Accepts a branch, tag, remote ref, or sha |
| `commitCount(since:at:)` | `Int?` | `.revListCount(since:)` (`<since>..HEAD`) | `nil` |
| `commitCount(from:to:at:)` | `Int?` | `.revListCountRange(base:tip:)` (`base..tip`) | `nil` |
| `isAncestor(_:of:at:)` | `Bool` | `.isAncestor(ancestor:descendant:)` | `false` (any non-zero) |
| `isIgnored(path:at:)` | `Bool` | `.checkIgnore(path:)` | exit 1 → `false`. Other non-zero exits throw |
| `hasUncommittedChanges(at:)` | `Bool` | `.statusPorcelain` | throws |
| `uncommittedPaths(at:)` | `[String]` | `.statusPorcelainPaths` | throws. Includes both paths of a rename. Untracked files are listed individually |
| `untrackedPaths(at:)` | `[String]` | `.statusPorcelainPaths` | throws |
| `uncommittedFiles(at:)` | `[UncommittedFile]` | `.statusPorcelainCollapsed` | throws. Untracked **directories are collapsed** (`--untracked-files=normal`) |
| `uncommittedFileCounts(at:)` | `UncommittedFileCounts` | `.statusPorcelainPaths` | throws |
| `pathsRestoredByReset(to:at:)` | `[String]` | `.diffPathsMissingFromHead(target:)` | throws. Paths in `target` that are absent from HEAD |
| `unversionedPaths(overlapping:ignoringCase:at:)` | `[String]` | `.lsFilesOthers(paths:)` | throws. Empty input returns `[]` without running anything. With `ignoringCase: false` the pathspecs are the paths plus every parent folder. With `true` no pathspecs are passed, so **every** untracked file is returned and the caller filters |
| `fileNamesIgnoreCase(at:)` | `Bool` | `.configGet(key: "core.ignorecase")` | via `configValue`. `true` for true/yes/on/1 |

### Branches

| Method | Returns | Command | Non-zero exit |
|--------|---------|---------|---------------|
| `currentBranch(at:)` | `String?` | `.branchShowCurrent` | throws. `nil` when detached (empty output) |
| `localBranchNames(at:)` | `[String]` | `.localBranchRefs` | throws |
| `remoteBranchNames(at:)` | `[String]` | `.remoteBranchRefs` | throws. `origin/main` form. `*/HEAD` excluded |
| `localBranches(at:)` | `[LocalBranch]` | `.localBranchDetails` | throws. One call gives worktree path and ahead/behind |
| `upstream(of:at:)` | `BranchUpstream?` | `.upstreamDetails(branch:)` | throws. `nil` when there's no upstream |
| `symbolicRef(_:at:)` | `String?` | `.symbolicRefShort(ref:)` | `nil` |
| `commit(of:at:)` | `String?` | `.revParseCommit(ref: "refs/heads/<branch>")` | `nil` when the local branch doesn't exist |
| `createAndSwitchToBranch(_:at:)` | `Void` | `.switchCreate(branch:)` | throws |
| `switchToBranch(_:at:)` | `Void` | `.switchBranch(branch:)` | throws |
| `switchToNewTrackingBranch(for:at:)` | `Void` | `.switchTrack(remoteBranch:)` | throws. Pass `origin/login`. Creates `login` tracking it |
| `moveBranch(_:to:at:)` | `Void` | `.branchForce(branch:target:)` | throws |
| `deleteBranch(_:at:)` | `Void` | `.deleteBranchForce(branch:)` (`branch -D`) | throws. **Doesn't check merge status**, so the caller must |
| `branchNames(mergedInto:at:)` | `[String]?` | `.mergedBranches(ref:)` | `nil` when `ref` doesn't resolve |
| `mergedByRef(candidateRefs:at:)` | `[String: [String]]` | `.mergedBranches(ref:)` per ref | Refs that don't resolve are **absent** from the dictionary |
| `contentMergedBranches(_:into:at:)` | `[String]` | `.revParseTree(ref:)` then `.mergeTreeWriteTree(base:branch:)` per branch | Unresolvable `ref` → `[]`. A branch counts as merged when merging it leaves `ref`'s tree unchanged (squash, rebase, or cherry-pick merges). Conflicts and failures count as not merged. git < 2.38 → always `[]` |
| `contentMergedByRef(mergedByRef:localBranchNames:at:)` | `[String: [String]]` | as above, per ref | For each ref, runs `contentMergedBranches` on the local branches **not** already in `mergedByRef[ref]` |

### Commits & Index

| Method | Returns | Command | Non-zero exit |
|--------|---------|---------|---------------|
| `stageAll(at:)` | `Void` | `.addAll` | throws |
| `commit(message:at:)` | `Void` | `.commit(message:)` | throws |
| `commitAllowingEmpty(message:at:)` | `Void` | `.commitAllowingEmpty(message:)` | throws |
| `indexTree(at:)` | `String` (tree sha) | `.writeTree` | throws. Snapshot the index |
| `restoreIndex(toTree:at:)` | `Void` | `.readTree(tree:)` | throws. Restore a snapshot |
| `stagedDiff(at:)` | `String` | `.diffCached` | throws. No color, no external diff |
| `commitSummaries(in:at:)` | `[String]` | `.logOneline(range:)` | throws. `"<short> <subject>"` lines |
| `commitMessages(since:paths:at:)` | `[String]` | `.logMessages(since:paths:)` | throws. Full bodies, no merges. `since: nil` means all of HEAD. `paths: []` means no path filter. Paths are **glob** pathspecs (no `--literal-pathspecs`) |
| `recentCommits(limit:at:)` | `[CommitSummary]` | `.logFirstParent(limit:)` | throws. Malformed record → `GitError.unreadableOutput` |
| `commitActivity(refs:since:author:at:)` | `[CommitActivity]` | `.logActivity(refs:since:author:)` | throws. `since` goes to `--since`. `author` is a fixed-string match. No merges or renames |
| `commitChanges(in:at:)` | `[CommitChanges]` | `.logCommitChanges(range:)` | throws. Oldest first, no merges or renames |

### Discard & Reset

| Method | Returns | Command | Non-zero exit |
|--------|---------|---------|---------------|
| `unstageAll(at:)` | `Void` | `.resetIndex` | throws |
| `unstage(paths:at:)` | `Void` | `.resetIndexPaths(paths:)` | throws. Literal pathspecs |
| `resetHardToHead(at:)` | `Void` | `.resetHardHead` | throws |
| `reset(to:mode:at:)` | `Void` | `.reset(mode:target:)` | throws. `GitResetMode.soft` / `.hard` |
| `restoreWorktree(at:)` | `Void` | `.restoreWorktree` (`checkout -- .`) | throws |
| `restoreFromIndex(path:at:)` | `Void` | `.restoreFromIndex(path:)` | throws. Literal pathspec |
| `restoreFromHead(path:at:)` | `Void` | `.restoreFromHead(path:)` | throws. Literal pathspec |
| `cleanUntracked(at:)` | `Void` | `.cleanUntracked` (`clean -fd`) | throws |
| `cleanUntracked(path:at:)` | `Void` | `.cleanPath(path:)` | throws. Literal pathspec |

### Tracking

| Method | Returns | Command | Non-zero exit |
|--------|---------|---------|---------------|
| `trackedPaths(at:)` | `[String]` | `.lsFilesTracked` | throws. Split on NUL, **not trimmed** |
| `ignoredTrackedPaths(at:)` | `[String]` | `.lsFilesIgnoredTracked` | throws. Split on NUL, not trimmed. Deduplicated, order kept |
| `removeFromIndex(paths:at:)` | `Void` | `.removeCached(paths:)` **per batch** | throws. Paths are split into batches of about 128 KB of argument bytes, so a very long list runs several commands |

### Remotes, Fetch & Push

| Method | Returns | Command | Non-zero exit |
|--------|---------|---------|---------------|
| `remoteNames(at:)` | `[String]` | `.remote` | throws |
| `remoteURL(of:at:)` | `String?` | `.remoteGetURL(name:)` | `nil` |
| `remoteHeadBranches(for:at:)` | `[String: String]` | `.symbolicRefShort(ref: "refs/remotes/<remote>/HEAD")` per remote | Remotes without HEAD are absent. Values look like `origin/main` |
| `setRemoteHead(_:for:at:)` | `Void` | `.remoteSetHead(remote:branch:)` | throws |
| `fetchAllTags(at:)` | `Bool` | `.fetchAllTags` | `false` |
| `fetchAllPruned(at:)` | `FetchResult` | `.fetchAllPruned` | `.failed(output:)` |
| `pullFastForward(at:)` | `Void` | `.pullFastForward` | throws |
| `fastForward(to:at:)` | `Void` | `.mergeFastForward(ref:)` | throws |
| `pushBranch(_:to:at:)` | `Void` | `.pushBranch(remote:branch:)` | throws |
| `pushBranchSettingUpstream(_:to:at:)` | `Void` | `.pushSettingUpstream(remote:branch:)` | throws |
| `pushHead(to:at:)` | `Void` | `.pushHead(remote:)` | throws |
| `pushTag(_:to:at:)` | `Void` | `.pushTag(remote:tag:)` (`refs/tags/<tag>`) | throws |
| `push(_:to:on:at:)` | `Void` | `.pushRefspec(remote:source:destination:)` | throws. `source:destination` refspec |
| `commitsBehindUpstream(of:at:)` | `Int?` | `.revListCountBehindUpstream(branch:)` | `nil` (e.g. no upstream). Pass `"HEAD"` for the checked-out branch |
| `commitsAheadOfUpstream(of:at:)` | `Int?` | `.revListCountAheadOfUpstream(branch:)` | `nil`. Pass `"HEAD"` for the checked-out branch |

### Worktrees

| Method | Returns | Command | Non-zero exit |
|--------|---------|---------|---------------|
| `worktrees(at:)` | `[Worktree]` | `.worktreeList` | throws. Main checkout first (`primary == true`) |
| `addWorktree(at:newBranch:from:in:)` | `Void` | `.worktreeAddNewBranch(path:branch:base:)` | throws. New branch, no tracking |
| `addWorktree(at:branch:in:)` | `Void` | `.worktreeAdd(path:branch:)` | throws. Existing local branch |
| `addWorktree(at:trackingBranch:remoteBranch:in:)` | `Void` | `.worktreeAddTracking(path:branch:remoteBranch:)` | throws. New branch tracking the remote |
| `removeWorktree(at:force:in:)` | `Void` | `.worktreeRemove(path:force:)` | throws |
| `pruneWorktrees(at:)` | `Void` | `.worktreePrune` | throws |

Worktree methods name the worktree with `at worktreePath:` and the repository with `in path:`.

`WorktreeRemovalForce`: `.none` (no flag), `.discardChanges` (`--force`, removes a worktree with changes), `.overrideLock` (`--force --force`, also removes a locked worktree).

### Tags, Config, Init

| Method | Returns | Command | Non-zero exit |
|--------|---------|---------|---------------|
| `tagNames(at:)` | `[String]` | `.tagList` | throws |
| `createTag(named:at:)` | `Void` | `.createTag(name:)` | throws. Lightweight tag |
| `commit(ofTag:at:)` | `String?` | `.revParseCommit(ref: "refs/tags/<name>")` | `nil` |
| `configValue(for:at:)` | `String?` | `.configGet(key:)` | exit 1 (unset) → `nil`. Other non-zero exits throw. Empty value → `nil` |
| `initializeRepository(branch:at:)` | `Void` | `.initialize(branch:)` | throws |
<!-- /type:GitClient -->

---

<!-- type:GitHubClient -->
## Struct: GitHubClient

```swift
public struct GitHubClient: Sendable {
    public init(runner: any GitCommandRunner)
}
```

`repo` arguments are `"owner/name"`. Most commands run with a `nil` working directory. The exceptions take `at path:`.

**API reads** (`gh api`) return `nil` when the failure output contains `(HTTP 404)` and throw `GitHubError.requestFailed(endpoint:output:)` for any other failure. **Other gh commands** throw `GitHubError.commandFailed` on non-zero exit.

### Auth & Repos

| Method | Returns | Command (path) | Failure |
|--------|---------|----------------|---------|
| `isAuthenticated()` | `Bool` | `.authStatus` (nil) | `false` |
| `authenticatedLogin()` | `String?` | `.apiRead(endpoint: "user", jq: ".login")` (nil) | API read |
| `repoExists(_:)` | `Bool` | `.apiRead(endpoint: "repos/<repo>", jq: ".full_name")` (nil) | 404 → `false` |
| `repositoryOwner(at:)` | `String?` | `.repoOwner` (path) | **throws** `commandFailed` |
| `repositoryNameWithOwner(at:)` | `String?` | `.repoNameWithOwner` (path) | **`nil`** on any non-zero exit |
| `repositoryVisibility(of:)` | `RepoVisibility` | `.repoVisibility(repo:)` (nil) | throws. Unknown value → `unexpectedOutput` |
| `defaultBranch(of:)` | `String` | `.repoDefaultBranch(repo:)` (nil) | throws. Empty → `unexpectedOutput` |
| `fileContents(atPath:in:)` | `String?` | `.apiReadRaw(endpoint: "repos/<repo>/contents/<path>")` (nil) | API read. Raw, untrimmed content |
| `licenseSPDX(in:)` | `String?` | `.apiRead(endpoint: "repos/<repo>/license", jq: ".license.spdx_id")` (nil) | API read. `NOASSERTION` → `nil` |
| `createRepo(_:visibility:license:)` | `Void` | `.createRepo(repo:visibility:license:)` (nil) | throws |
| `createRepo(_:visibility:description:sourcePath:remote:)` | `Void` | `.createRepoFromSource(...)` (nil) | throws. Creates a GitHub repo from an existing local repo and adds `remote`. Does not push commits (`--push` is not passed) |
| `cloneRepo(_:into:)` | `Void` | `.cloneRepo(repo:destinationPath:)` (nil) | throws |

### Pull Requests

| Method | Returns | Command (path) | Failure |
|--------|---------|----------------|---------|
| `openPullRequestURL(head:in:)` | `String?` | `.openPullRequestURLs(repo:head:)` (nil) | throws. First open PR URL for that head branch, or `nil` |
| `pullRequest(number:in:)` | `PullRequestDetails` | `.pullRequestDetails(repo:number:)` (nil) | throws. Malformed output → `unexpectedOutput` |
| `createPullRequest(base:head:in:at:)` | `String` (PR URL) | `.createPullRequest(repo:base:head:)` (path) | throws. Uses `--fill`. Returns the last output line. Empty output → `unexpectedOutput` |

### Releases

| Method | Returns | Command (path) | Failure |
|--------|---------|----------------|---------|
| `latestReleaseTag(in:)` | `String?` | `.apiRead(endpoint: "repos/<repo>/releases/latest", jq: ".tag_name")` (nil) | API read |
| `releaseAssetNames(in:tag:)` | `[String]?` | `.apiRead(endpoint: "repos/<repo>/releases/tags/<tag>", jq: ".assets[].name")` (nil) | API read. `nil` means no such release |
| `createRelease(tag:title:notesFilePath:at:)` | `String` | `.createRelease(tag:title:notesFilePath:)` (path) | throws. Release in the repo at `path` |
| `createRelease(tag:title:notesFilePath:assetPaths:in:)` | `String` | `.createRemoteRelease(...)` (nil) | throws. Release in `repo` with assets |
| `uploadReleaseAssets(_:tag:in:)` | `Void` | `.uploadReleaseAssets(repo:tag:assetPaths:)` (nil) | throws |
| `downloadReleaseAssets(tag:in:into:)` | `Void` | `.downloadReleaseAssets(repo:tag:destinationPath:)` (nil) | throws |
<!-- /type:GitHubClient -->

---

## Value Types

All are `Sendable` and `Equatable` structs or enums with public memberwise initializers.

<!-- type:LocalBranch -->
### LocalBranch
`name`, `worktreePath: String?` (the worktree holding it checked out, including the main checkout), `upstreamName: String?` (e.g. `origin/main`), `upstreamGone: Bool`, `ahead: Int`, `behind: Int` (0 when there's no upstream).
<!-- /type:LocalBranch -->

<!-- type:BranchUpstream -->
### BranchUpstream
`name` (`origin/feature`), `remote` (`origin`), `mergeRef` (`refs/heads/feature`), `remoteBranchIsGone: Bool`.
<!-- /type:BranchUpstream -->

<!-- type:Worktree -->
### Worktree
`path`, `branch: String?` (without `refs/heads/`, `nil` when detached or bare), `primary`, `detached`, `locked`, `lockReason: String?`, `prunable` (the directory is gone).
<!-- /type:Worktree -->

<!-- type:UncommittedFile -->
### UncommittedFile
`path`, `originalPath: String?` (rename source), `hasStagedChanges`, `hasUnstagedChanges`, `untracked`, `conflicted`, `existsInHead`, `change: UncommittedFile.Change` (`.added`, `.modified`, `.deleted`). Untracked files count as `.added`, and conflicts as `.modified` with both staged and unstaged changes.
<!-- /type:UncommittedFile -->

<!-- type:UncommittedFileCounts -->
### UncommittedFileCounts
`added`, `modified`, `deleted`. `UncommittedFileCounts.clean` is all zeros.
<!-- /type:UncommittedFileCounts -->

<!-- type:CommitSummary -->
### CommitSummary
`sha`, `shortSha`, `subject`, `authorName`, `authorEmail`, `relativeDate` (e.g. `"2 days ago"`), `parentCount` (2+ means a merge).
<!-- /type:CommitSummary -->

<!-- type:CommitActivity -->
### CommitActivity
`shortSha`, `day` (`YYYY-MM-DD`, local time), `files: [FileChange]`.
<!-- /type:CommitActivity -->

<!-- type:CommitChanges -->
### CommitChanges
`shortSha`, `date` (`YYYY-MM-DD`), `subject`, `files: [FileChange]`, `createdPaths`, `deletedPaths`.
<!-- /type:CommitChanges -->

<!-- type:FileChange -->
### FileChange
`path`, `added: Int?`, `deleted: Int?`. Both are `nil` for binary files.
<!-- /type:FileChange -->

<!-- type:PullRequestDetails -->
### PullRequestDetails
`headBranch`, `pullRequestIsOpen`, `headIsInFork`.
<!-- /type:PullRequestDetails -->

<!-- type:FetchResult -->
### FetchResult
`.fetched` or `.failed(output: String)`.
<!-- /type:FetchResult -->

<!-- type:RepositoryRootLookup -->
### RepositoryRootLookup
`.found(path: String)` or `.notFound(output: String)`. Use it instead of `repositoryRoot` when you need git's reason.
<!-- /type:RepositoryRootLookup -->

<!-- type:RepoVisibility -->
### RepoVisibility
`String` raw values: `.public`, `.private`, `.internal`.
<!-- /type:RepoVisibility -->

<!-- type:GitResetMode -->
### GitResetMode
`.soft`, `.hard`.
<!-- /type:GitResetMode -->

---

<!-- type:GitError -->
## Enum: GitError

```swift
public enum GitError: Error, Sendable {   // LocalizedError; NOT Equatable
    case commandFailed(command: GitCommand, exitCode: Int32, output: String)
    case unreadableOutput(command: GitCommand, output: String)
}
```

`errorDescription` for `commandFailed` renders `` `git <args>` failed with exit code N. `` followed by the output on a new line when the output is non-empty. `unreadableOutput` is thrown when a log record can't be parsed, and renders `` Couldn't read the output of `git <args>`: `` followed by the output. The rendered args exclude `-C <path>`.
<!-- /type:GitError -->

<!-- type:GitHubError -->
## Enum: GitHubError

```swift
public enum GitHubError: Error, Equatable, Sendable {   // LocalizedError
    case requestFailed(endpoint: String, output: String)                    // gh api failure other than 404
    case commandFailed(command: GitHubCommand, exitCode: Int32, output: String)
    case unexpectedOutput(command: GitHubCommand, output: String)           // unparseable gh response
}
```

Descriptions are user-facing and tell the user to check `gh auth status` and their network connection, or to update gh for `unexpectedOutput`.
<!-- /type:GitHubError -->

---

<!-- type:DefaultBranch -->
## Default-Branch Helpers

Pure functions with no runner. Feed them client results. All are caseless enums with static methods.

```swift
public enum DefaultBranchConventions {
    public static let remote = "origin"
    public static let branchNames = ["main", "master"]
    public static let remoteHeadName = "HEAD"
}
```

| API | Returns | Behavior |
|-----|---------|----------|
| `DefaultBranchDetector.detect(remoteHeadBranches:upstreamRemote:configuredDefaultBranch:localBranchNames:)` | `String?` (branch name) | Takes the remote HEAD of `upstreamRemote`, else `origin`, else the alphabetically first remote, with the remote prefix stripped. Otherwise uses the non-empty `configuredDefaultBranch`, else the first of `main`/`master` that exists locally |
| `DefaultBranchRefDetector.detect(defaultBranch:remoteBranchNames:)` | `String?` (remote ref) | Prefers `origin/<defaultBranch>`, else the alphabetically first `<remote>/<defaultBranch>` |
| `DefaultRefCandidatesBuilder.make(localBranchNames:remoteBranchNames:remoteHeadBranches:configuredDefaultBranch:)` | `[String]` | The remote refs, then the local branches, whose name matches a remote-HEAD branch, the configured default, `main`, or `master`. `<remote>/HEAD` is excluded |
| `RemoteBranchRef.branchName(of:)` | `String?` | Text after the first `/` (`origin/feat/x` → `feat/x`). `nil` without a slash |
| `RepositoryWebURL.make(remoteURL:)` | `String?` | `git@host:o/r.git`, `ssh://…` (any port is dropped), or portless `https://…` → `https://host/o/r`. Also `nil` when the host has characters other than letters, digits, `.`, or `-`. Anything else → `nil` |

### Typical composition

```swift
let git = GitClient(runner: runner)
let remotes = try git.remoteNames(at: repo)
let heads = try git.remoteHeadBranches(for: remotes, at: repo)
let upstreamRemote = try git.currentBranch(at: repo).flatMap { try git.upstream(of: $0, at: repo)?.remote }

let defaultBranch = DefaultBranchDetector.detect(
    remoteHeadBranches: heads,
    upstreamRemote: upstreamRemote,
    configuredDefaultBranch: nil,
    localBranchNames: try git.localBranchNames(at: repo)
)
```
<!-- /type:DefaultBranch -->

---

## Best Practices

- **Depend on `GitCommandRunner`, construct clients at the edge.** Inject `GitClient`/`GitHubClient` (or the runner) so tests can use `NnGitTesting`.
- **Never throw from a runner for non-zero exits.** If you do, every optional or Bool method (`commit(of:)`, `isAncestor`, `configValue`, 404 handling) stops working.
- **Return combined output.** gh writes `(HTTP 404)` to stderr. A runner that drops stderr turns every "not found" into `requestFailed`.
- **Choose the status method by command.** `uncommittedFiles` collapses untracked directories. `uncommittedPaths` and `untrackedPaths` list every file.
- **`deleteBranch` force-deletes.** Check merge status first with `branchNames(mergedInto:)` or `contentMergedBranches`.
- **Snapshot and restore the index** with `indexTree` and `restoreIndex(toTree:)` around operations that touch staging.
- **`repositoryOwner` throws where `repositoryNameWithOwner` returns `nil`.** Use the latter to probe whether a directory has a GitHub remote.
