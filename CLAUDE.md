# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
swift build                                              # Build all targets
swift test                                               # Run all tests
swift test --filter NnGitKitTests.GitClientBranchesTests # Run a single test suite
```

## Skill Documentation

`Skills/NnGitKit/` holds the API-reference skill for this package (`SKILL.md`, `ApiReference.md`,
`TestingReference.md`). It lives here so the API and its documentation change in the same PR.

- **Any PR changing the public API must update `Skills/`.** Nothing enforces this in CI, so check it
  by hand whenever a PR touches `public` declarations in `Sources/`. `ApiReference.md` lists the
  `GitCommand`/`GitHubCommand` case each client method runs and how it treats non-zero exits, so
  changing either one is an API change for the docs too.
- **`Skills/NnGitKit/.claude-plugin/plugin.json` deliberately has no `version` field.**
- **SwiftPM ignores `Skills/`.** It is not a target and must not become one.
- `Skills/NnGitKit/skills/NnGitKit/manifest.json` pins the sha and per-file hashes of the `Sources/`
  state the docs describe. Regenerate it when the docs are updated.

Requires Swift 6.4 tools and macOS 15+. Every target treats warnings as errors.

## Architecture

NnGitKit is a dependency-free Swift package (macOS-only, SPM-only) with two library targets:

**NnGitKit**: typed commands plus clients that run and parse them.
- `Running/`: `GitCommand` and `GitHubCommand` enums model each `git`/`gh` invocation. `GitCommand.arguments(at:)` produces `["-C", path, ...]`, and `GitHubCommand.arguments` produces the `gh` argument list. `GitCommandRunner` is the protocol consumers implement. It returns `GitCommandOutput(exitCode:output:)` and does not throw for non-zero exits.
- `Client/`: `GitClient` and `GitHubClient` are `Sendable` structs wrapping a runner. Each feature area is its own extension file (`GitClient+Branches`, `+Status`, `+Commits`, `+Remotes`, `+Tracking`, `+Worktrees`, `+Discard`, `+Reset`, `+Tags`, `+Config`, `+Init`, and `GitHubClient+Repos`, `+PullRequests`, `+Releases`), along with the value types they return. Failures surface as `GitError` and `GitHubError` (both `LocalizedError`).
- `DefaultBranch/`: helpers for detecting a repo's default branch from candidate refs.

**NnGitTesting**: test doubles that re-export NnGitKit.
- `MockGitCommandRunner` returns scripted results matched by command and path, and throws `UnexpectedCommand` for anything unscripted.
- `RecordingGitCommandRunner` wraps the mock and records every call (`gitCommands`, `gitHubCommands`).

## Key Patterns

- **The package never launches processes.** All execution goes through a consumer-supplied `GitCommandRunner`. NnGitKit must stay free of any shell or process dependency.
- **Arguments, not shell strings.** Every value is passed as its own argument, so names containing shell metacharacters stay literal.
- **Exit codes are data.** Runners report non-zero exits, and clients decide whether that is an error (`runExpectingSuccess`) or a meaningful answer (for example, `isAncestor`, or a 404 from the GitHub API meaning "not found").
- New git or gh functionality means adding a `GitCommand`/`GitHubCommand` case with its arguments, a client method that runs and parses it, and tests at both levels.

## Testing Conventions

- Uses Swift Testing (`import Testing`, `@Test`, `#expect`), not XCTest.
- Client tests script runner results with `MockGitCommandRunner.GitResult`/`GitHubResult` and assert the exact command sequence through `RecordingGitCommandRunner`.
- `CommandArgumentsTests` verifies the argument list produced for each command case.
