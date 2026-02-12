# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/nikolainobadi/NnGitKit/compare/v0.6.1...HEAD
[0.6.1]: https://github.com/nikolainobadi/NnGitKit/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/nikolainobadi/NnGitKit/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/nikolainobadi/NnGitKit/releases/tag/v0.5.0
