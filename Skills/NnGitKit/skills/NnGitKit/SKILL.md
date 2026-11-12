---
name: NnGitKit
description: NnGitKit Swift API reference for running git and gh from Swift through typed commands. USE WHEN importing NnGitKit or NnGitTesting, using GitClient or GitHubClient, implementing GitCommandRunner, GitCommand or GitHubCommand cases, GitCommandOutput, GitError, GitHubError, reading branches, status, commits, stashes, worktrees, remotes, tags, or config from Swift, cloning a repository, creating GitHub repos, pull requests, or releases with gh, detecting a default branch, MockGitCommandRunner, RecordingGitCommandRunner, UnexpectedCommand, testing code that uses GitClient or GitHubClient.
user-invocable: true
---

# NnGitKit

Dependency-free Swift package that models `git` and `gh` invocations as typed commands and parses their output into value types. It never launches processes: the consumer supplies a `GitCommandRunner`.

**Dependency:** `.package(url: "https://github.com/nikolainobadi/NnGitKit.git", from: "1.0.0")`
**Products:** `NnGitKit` (production), `NnGitTesting` (test doubles, re-exports NnGitKit)
**Platforms:** macOS 15+ | **Swift tools:** 6.4
<!-- package_path: . --> <!-- this skill lives inside the NnGitKit repo it documents -->

> This skill lives in the NnGitKit repo under `Skills/NnGitKit/`. Any PR changing the
> package's public API must update it in the same change.

## Context Files

| File | Purpose | Load When |
|------|---------|-----------|
| `ApiReference.md` | GitCommandRunner, GitClient, GitHubClient, value types, errors, default-branch helpers. Every method with the command it runs and how it treats non-zero exits | Calling git/gh from Swift, writing a runner, choosing a client method, handling errors |
| `TestingReference.md` | MockGitCommandRunner, RecordingGitCommandRunner, scripting results, asserting command sequences | Writing tests for code that uses GitClient or GitHubClient |

Both files sit next to this `SKILL.md`, so resolve their paths from this skill's folder, not from the project.

- **Before calling or recommending a client method**, read that method's section in `ApiReference.md`, for example "Branches" or "Releases". It's a large lookup file, so use its contents list instead of reading all of it. The row tells you the command the method runs and how it treats a non-zero exit, and you need both before handling its result.
- **Before writing a `GitCommandRunner`**, read the whole "Protocol: GitCommandRunner" section.
- **Before writing or fixing a test**, read `TestingReference.md` completely. It's short, and the matching rules and the raw-output shapes both decide whether a scripted result is ever used.
- **If either file is missing**, read the matching package source instead: `Sources/NnGitKit/Client/GitClient+<Area>.swift`, `GitHubClient+<Area>.swift`, or `Sources/NnGitTesting/`. In a consumer project these are under `.build/checkouts/NnGitKit/`. Tell the user the reference was unavailable.

## Quick Reference

### Production
- **GitCommandRunner** is the protocol you implement (usually over NnShellKit or `Process`). `runGit(_:at:)` receives a `GitCommand` and a path. Run `git` with `command.arguments(at: path)`, which is `["-C", path, ...]`. `runGitHub(_:at:)` receives a `GitHubCommand` and an optional working directory. Run `gh` with `command.arguments`.
- **Runners must not throw for non-zero exits.** Return `GitCommandOutput(exitCode:output:)` and let the client decide. Throw only when the process couldn't be launched.
- **GitClient(runner:)** and **GitHubClient(runner:)** are `Sendable` structs. `GitClient` methods take `at path: String`, the repository directory. The exceptions are `addWorktree`/`removeWorktree`, which take `at worktreePath:` for the worktree and `in path:` for the repository, and `clone(url:to:)`, which takes only an absolute destination and runs in its parent folder.
- **Exit codes are data.** Most methods throw `GitError.commandFailed` on a non-zero exit. Lookups such as `commit(of:)`, `remoteURL(of:)`, `symbolicRef`, `headCommit`, and `repositoryRoot` return `nil` instead, and predicates such as `isAncestor` and `fetchAllTags` return `false`.
- **GitHub API reads** (`repoExists`, `latestReleaseTag`, `fileContents`, `licenseSPDX`, `authenticatedLogin`, `releaseAssetNames`) return `nil`/`false` on HTTP 404 and throw `GitHubError.requestFailed` otherwise.
- **Arguments, not shell strings.** Every value is passed as its own argument, so names containing spaces or shell metacharacters stay literal. The unstage, restore, clean, `unversionedPaths`, and `removeFromIndex` path arguments use `--literal-pathspecs`. `commitMessages(since:paths:)` does **not**, so git treats its paths as glob pathspecs.
- **Methods that look interchangeable run different commands.** `uncommittedFiles` collapses untracked directories (`.statusPorcelainCollapsed`). `uncommittedPaths`, `untrackedPaths`, and `uncommittedFileCounts` list every file (`.statusPorcelainPaths`). `deleteBranch` force-deletes without checking whether the branch is merged. `ignoredTrackedPaths` lists tracked files matching `.gitignore`; `ignoredUntrackedPaths` lists untracked ignored files using every exclude source, collapsing ignored folders.
- **Default-branch helpers** (`DefaultBranchDetector`, `DefaultBranchRefDetector`, `DefaultRefCandidatesBuilder`) are pure functions. You feed them the output of client calls.

### Testing
- Import `NnGitTesting`. It re-exports NnGitKit.
- **MockGitCommandRunner(gitResults:gitHubResults:)** returns the first scripted result matching **both command and path**. Anything unscripted throws `UnexpectedCommand`. There's no sequencing, so the same command at the same path always gets the same result.
- **RecordingGitCommandRunner** wraps the mock and records every call, including unscripted ones, in `gitCalls`/`gitHubCalls` (`gitCommands`/`gitHubCommands` for commands only).
- Assert exact command sequences: `#expect(runner.gitCommands == [.statusPorcelain, .addAll, .commit(message: "x")])`.
- `GitHubError` is `Equatable`, so `#expect(throws: GitHubError.x)` works. `GitError` is **not** `Equatable`, so match it with `#expect(throws: GitError.self)` or a pattern.

## Examples

- "How do I get the current branch from Swift?" -> Loads ApiReference.md
- "How do I implement GitCommandRunner with NnShellKit?" -> Loads ApiReference.md
- "Which methods return nil instead of throwing?" -> Loads ApiReference.md
- "How do I open a pull request with GitHubClient?" -> Loads ApiReference.md
- "How do I test code that calls GitClient?" -> Loads TestingReference.md
- "Why does my test throw UnexpectedCommand?" -> Loads TestingReference.md
