# NnGitKit

![CI](https://github.com/nikolainobadi/NnGitKit/actions/workflows/ci.yml/badge.svg)
![Swift Version](https://badgen.net/badge/swift/6.0%2B/purple)
![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey)
![SPM](https://img.shields.io/badge/Distribution-SPM%20only-red)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

NnGitKit is a Swift package designed to simplify interactions with Git and the GitHub CLI (`gh`). I built this package because I can never remember all the different commands available, and I wanted a more intuitive way to work with Git and GitHub directly from Swift.  

The package wraps common Git and GitHub operations in easy-to-use commands, making it quick to initialize repositories, manage branches, push changes, and more.  

> **Note:** This package is a work in progress. I add new commands as I find a need for them. Contributions and feedback are welcome!  

## Features

- Simplified Git initialization and commits  
- Remote repository management with GitHub CLI integration  
- Branch management and cleanup  
- Command generation for both Git and GitHub operations  
- Extensible design to easily add new commands  

## Installation

Add the package to your Swift project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/nikolainobadi/NnGitKit.git", from: "0.6.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            // Use only this if you need GitShellKit (it exports GitCommandGen)
            .product(name: "GitShellKit", package: "NnGitKit"),
            
            // Alternatively, use this directly if you only need GitCommandGen
            .product(name: "GitCommandGen", package: "NnGitKit"),
        ]
    )
]
```

## Usage

## Creating Git Commands and GitHub Commands

You can create Git and GitHub commands using `GitShellCommand` and `GitHubShellCommand`, respectively.  
These commands generate shell-compatible strings that you can execute with any shell implementation.  

```swift
import GitCommandGen

// Creating a Git command to initialize a new repository
let initCommand = makeGitCommand(.gitInit, path: "/path/to/project")
print("Git Init Command: \(initCommand)")

// Creating a GitHub command to create a remote repository
let createRepoCommand = makeGitHubCommand(.createRemoteRepo(name: "MyAwesomeRepo", visibility: "public", details: "An awesome repo"), path: "/path/to/project")
print("GitHub Create Repo Command: \(createRepoCommand)")

```

## Using Default Methods in GitShell

NnGitKit includes some default methods for common Git operations. One of the most useful is `getRemoteURL`, which correctly maps the output of a standard Git remote URL to an HTTPS URL.  

```swift
// Using the default GitShell methods to get a remote URL
let shell = GitShellAdapter()

do {
    let url = try shell.getGitHubURL(at: "/path/to/project")
    print("GitHub URL: \(url)")
} catch {
    print("Error fetching GitHub URL: \(error)")
}

// Original output from Git: git@github.com:username/repo.git
// Transformed URL: https://github.com/username/repo

```

To resolve the default branch configured for a repository path:

```swift
let defaultBranch = try shell.getDefaultBranch(at: "/path/to/project")
print("Default branch: \(defaultBranch)")
```

You can also plan commands without executing them using `ExecutionMode.dryRun`:

```swift
let gitStarter = GitStarter(path: "/path/to/project", shell: YourShellImplementation())
let planned = try gitStarter.gitInit(mode: .dryRun)
print(planned) // ["git -C \"/path/to/project\" rev-parse --is-inside-work-tree", ...]
```

When a command fails, `GitCommandFailure` includes the command string and any available output to aid diagnostics.

### Initializing a Git Repository

```swift 
import NnGitKit

let gitStarter = GitStarter(path: "/path/to/project", shell: YourShellImplementation())

do {
    try gitStarter.gitInit()
    print("Repository initialized successfully.")
} catch {
    print("Failed to initialize repository: \(error)")
}

```

### Creating a GitHub Repository

```swift
let info = RepoInfo(
    name: projectName,
    details: projectDetails,
    visibility: visibility,
    branchPolicy: .mainOnly,
    defaultBranch: "main" // customize if your repo uses a different default branch
)
let repoStarter = GitHubRepoStarter(path: "/path/to/project", shell: YourShellImplementation(), repoInfo: info)

do {
    let url = try repoStarter.repoInit()
    print("Repository created at \(url)")
} catch {
    print("Error creating repository: \(error)")
}
```

## Using SwiftShell for Shell Operations (optional)

Although NnGitKit is shell-agnostic, you can easily use it with **[SwiftShell](https://github.com/kareman/SwiftShell)** to handle shell operations.  
Here’s an example of creating a `GitShellAdapter` that leverages SwiftShell to execute commands:

```swift
import SwiftShell
import GitShellKit

/// An adapter that uses SwiftShell to execute Git commands.
struct GitShellAdapter: GitShell {
    func runWithOutput(_ command: String) throws -> String {
        let output = run(bash: command)
        
        if output.succeeded {
            return output.stdout
        } else {
            throw output.error ?? NSError(domain: "GitShellAdapterError", code: 1, userInfo: nil)
        }
    }
}
```

### Usage Example

```swift
let shell = GitShellAdapter()
let gitStarter = GitStarter(path: "/path/to/project", shell: shell)

do {
    try gitStarter.gitInit()
    print("Repository initialized successfully.")
} catch {
    print("Failed to initialize repository: \(error)")
}
```

## Contributing

Feel free to submit issues or pull requests. If you have ideas for new commands or improvements, I’d love to hear from you!

## License

NnGitKit is available under the MIT license. See the [LICENSE](LICENSE) file for more information.
