# NnGitKit skill

A Claude Code reference skill for [NnGitKit](https://github.com/nikolainobadi/NnGitKit). It teaches Claude the package's API: typed `git`/`gh` commands, `GitClient`, `GitHubClient`, the `GitCommandRunner` protocol, and the `NnGitTesting` test doubles. That way Claude uses the real method names and exit-code behavior instead of guessing.

## Installation

The skill ships as a Claude Code plugin from the `Skills/NnGitKit/` folder of the NnGitKit repo, and `.claude-plugin/plugin.json` there describes it. Install it through whichever plugin marketplace lists that folder. Being in the repo doesn't install it on its own.

## Invocation

Claude loads it automatically when a request involves NnGitKit, for example "get the current branch with GitClient" or "write a test for my GitHubClient release code". It is user-invocable, so it also appears among the slash commands once the plugin is installed. The exact name depends on the plugin namespace.

## Files

| File | Role |
|------|------|
| `SKILL.md` | The entry file Claude reads first: quick reference, gotchas, and when to open each reference |
| `ApiReference.md` | Every client method with the command it runs and its non-zero-exit behavior, plus value types, errors, and default-branch helpers |
| `TestingReference.md` | `MockGitCommandRunner` / `RecordingGitCommandRunner` rules, a complete test example, and the raw output shapes each parser expects |
| `manifest.json` | The commit sha and per-file hashes of the `Sources/` state these docs describe |

## Maintenance

Update these files in the same PR as any public API change in `Sources/`. Afterwards, regenerate `manifest.json` so its hashes match the documented source. If a marketplace pins this plugin to a tag, consumers see doc changes only after the next release, not when a change merges.
