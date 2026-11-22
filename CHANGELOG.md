# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-11-22

### Added
- `GitClient.clone(url:to:)` to clone a repository to an absolute destination path; the parent folder must already exist and the destination must not.
- `GitClient.stashEntries(at:)` to list stashes as one string per entry in Git's order.
- `GitClient.ignoredUntrackedPaths(at:)` to list untracked files ignored by standard exclude sources, collapsing fully ignored folders into entries ending in `/`.
- `GitCommand.clone(url:destination:)`, `.stashList`, and `.lsFilesIgnoredOthers` for generating the corresponding Git command arguments.

## [1.0.0] - 2026-11-11

Full rewrite. NnGitKit now ships the standalone git/GitHub kit extracted from GitHappens. The 0.x API is removed; consumers that need it should stay on `0.6.x`.

### Added
- `NnGitKit` library: typed `GitCommand` / `GitHubCommand` enums that produce argument arrays, never shell strings
- `GitCommandRunner` protocol returning `GitCommandOutput` (exit code and output); supply your own process runner to execute commands
- `GitClient` covering status, branches, commits, remotes, tracking, tags, config, worktrees, discard/reset, merged-branch detection, and commit activity
- `GitHubClient` covering auth, repos, pull requests, and releases
- `GitError` and `GitHubError` with descriptive `LocalizedError` messages
- Default-branch detection helpers
- `NnGitTesting` library with `MockGitCommandRunner` and `RecordingGitCommandRunner`
- Claude Code reference skill in `Skills/NnGitKit/` covering the public API and test runners

### Changed
- Requires Swift 6.4 tools and macOS 15; upgrade your toolchain and deployment target before adopting 1.0.0 (breaking)
- Every target treats warnings as errors

### Removed
- `GitShellKit` and `GitCommandGen` libraries, including `GitShell`, `GitShellCommand`, `GitHubShellCommand`, `GitStarter`, `GitHubRepoStarter`, and `ReleaseNoteInfo`; replace product dependencies and imports with `NnGitKit` and adopt the new clients and runner, or stay on `0.6.x` (breaking)

## [0.6.1] - 2025-07-01

### Changed
- Add `branchName` parameter to `.listMergedBranches` for specifying the target branch

## [0.6.0] - 2025-06-09

### Added
- Add `runGitCommandWithOutput` convenience method on `GitShell` for running git commands directly

## [0.5.0] - 2025-03-25

### Added
- Initial release
- Git command generation via `GitShellCommand` enum and `makeGitCommand` helper
- GitHub CLI command generation via `GitHubShellCommand` enum and `makeGitHubCommand` helper
- `GitShell` protocol for shell-agnostic command execution
- `GitStarter` for initializing local git repositories
- `GitHubRepoStarter` for creating GitHub repositories via `gh` CLI
- `ReleaseNoteInfo` for handling release notes from text or file
- GitHub URL normalization (SSH to HTTPS conversion)
- Swift 6.0 strict concurrency support
- CI via GitHub Actions

[Unreleased]: https://github.com/nikolainobadi/NnGitKit/compare/1.1.0...HEAD
[1.1.0]: https://github.com/nikolainobadi/NnGitKit/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/nikolainobadi/NnGitKit/compare/v0.6.1...v1.0.0
[0.6.1]: https://github.com/nikolainobadi/NnGitKit/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/nikolainobadi/NnGitKit/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/nikolainobadi/NnGitKit/releases/tag/v0.5.0
