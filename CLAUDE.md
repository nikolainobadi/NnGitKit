# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
swift build                                    # Build all targets
swift test                                     # Run all tests
swift test --filter NnGitKitTests.GitStarterTests  # Run a single test suite
swift test --filter GitStarterTests/gitInitSuccess # Run a single test
```

## Architecture

NnGitKit is a Swift 6 package (macOS-only, SPM-only) with two library targets:

**GitCommandGen** — Pure command string generation, no side effects. Contains:
- `GitShellCommand` enum — Git CLI commands (init, commit, branch ops, etc.) with an `arg` computed property producing the shell argument string
- `GitHubShellCommand` enum — GitHub CLI (`gh`) commands with the same pattern
- `makeGitCommand(_:path:)` / `makeGitHubCommand(_:path:)` — Free functions that wrap commands with `git -C "path"` or `cd "path" &&` prefixes

**GitShellKit** — Execution layer that depends on GitCommandGen. Contains:
- `GitShell` protocol — Shell abstraction with `runWithOutput(_:)` and `runAndPrint(_:)`. All git execution flows through protocol extension helper methods on `GitShell` (e.g., `getGitHubURL`, `getDefaultBranch`, `inspectRepoState`)
- `GitStarter` — Initializes local git repos (init + add + commit)
- `GitHubRepoStarter` — Creates GitHub repos via `gh` CLI with validation (checks gh availability, auth, local git, remote absence, branch policy)
- `ExecutionMode` — `.execute` vs `.dryRun` for planning commands without running them
- `GitShellOutput` — Internal helper centralizing all git output parsing (truthy checks, remote detection, URL normalization, branch parsing)
- `GitCommandFailure` — Error type wrapping failed command string + output for diagnostics

GitShellKit re-exports GitCommandGen via `@_exported import`.

## Key Patterns

- **Shell abstraction**: All shell execution goes through the `GitShell` protocol. Consumers provide their own implementation (e.g., wrapping SwiftShell or Process). The package never executes shell commands directly.
- **Command generation is separated from execution**: `GitCommandGen` produces strings, `GitShellKit` runs them. Tests verify both layers independently.
- **ExecutionMode dual-path**: Methods like `gitInit(mode:)` and `repoInit(mode:)` accept `.execute` or `.dryRun`. In dry-run mode, commands are collected into a `[String]` array without execution.
- **Error wrapping**: `runWithOutputWrappingFailure` catches errors and re-throws as `GitCommandFailure` with the command string and output attached.
- **MockShell for testing**: Tests use `MockShell` which queues return values via `runResults: [String]` and can trigger errors at specific command indices via `errorIndices: Set<Int>`.

## Testing Conventions

- Uses Swift Testing framework (`import Testing`, `@Test`, `#expect`), not XCTest
- Test structs follow `makeSUT()` factory pattern returning `(sut:, shell:)` tuples
- Assertion helpers (e.g., `assertShellCommands`) verify the exact sequence of commands passed to MockShell
- Tests verify both execution behavior and dry-run command planning
