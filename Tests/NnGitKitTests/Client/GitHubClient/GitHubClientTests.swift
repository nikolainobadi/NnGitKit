import Testing
import NnGitKit
import NnGitTesting

struct GitHubClientTests {
    @Test
    func `A repo GitHub finds exists`() throws {
        let sut = makeSUT(command: repoExistsCommand, path: nil, output: success("nikolainobadi/nnex-releases"))

        #expect(try sut.repoExists("nikolainobadi/nnex-releases"))
    }

    @Test
    func `A repo GitHub reports as not found doesn't exist`() throws {
        let sut = makeSUT(command: repoExistsCommand, path: nil, output: notFound)

        #expect(try sut.repoExists("nikolainobadi/nnex-releases") == false)
    }

    @Test
    func `Any other failure throws instead of reporting a missing repo`() {
        let sut = makeSUT(command: repoExistsCommand, path: nil, output: failure("gh: Bad credentials (HTTP 401)"))

        #expect(throws: GitHubError.requestFailed(endpoint: "repos/nikolainobadi/nnex-releases", output: "gh: Bad credentials (HTTP 401)")) {
            try sut.repoExists("nikolainobadi/nnex-releases")
        }
    }
}

// MARK: - Latest Release
extension GitHubClientTests {
    @Test
    func `The latest release tag is read`() throws {
        let sut = makeSUT(command: latestReleaseCommand, path: nil, output: success("1.2.0"))

        #expect(try sut.latestReleaseTag(in: "nikolainobadi/nnex-releases") == "1.2.0")
    }

    @Test
    func `A repo without releases has no latest release tag`() throws {
        let sut = makeSUT(command: latestReleaseCommand, path: nil, output: notFound)

        #expect(try sut.latestReleaseTag(in: "nikolainobadi/nnex-releases") == nil)
    }
}

// MARK: - File Contents
extension GitHubClientTests {
    @Test
    func `A file's raw contents are read`() throws {
        let sut = makeSUT(command: fileContentsCommand, path: nil, output: success("class Nnex < Formula\nend"))

        #expect(try sut.fileContents(atPath: "Formula/nnex.rb", in: "nikolainobadi/homebrew-nn") == "class Nnex < Formula\nend")
    }

    @Test
    func `A missing file has no contents`() throws {
        let sut = makeSUT(command: fileContentsCommand, path: nil, output: notFound)

        #expect(try sut.fileContents(atPath: "Formula/nnex.rb", in: "nikolainobadi/homebrew-nn") == nil)
    }
}

// MARK: - License
extension GitHubClientTests {
    @Test
    func `The license's SPDX ID is read`() throws {
        let sut = makeSUT(command: licenseCommand, path: nil, output: success("MIT"))

        #expect(try sut.licenseSPDX(in: "nikolainobadi/nnex-releases") == "MIT")
    }

    @Test
    func `A license GitHub can't identify has no SPDX ID`() throws {
        let sut = makeSUT(command: licenseCommand, path: nil, output: success("NOASSERTION"))

        #expect(try sut.licenseSPDX(in: "nikolainobadi/nnex-releases") == nil)
    }

    @Test
    func `A repo without a license has no SPDX ID`() throws {
        let sut = makeSUT(command: licenseCommand, path: nil, output: notFound)

        #expect(try sut.licenseSPDX(in: "nikolainobadi/nnex-releases") == nil)
    }
}

// MARK: - Release Assets
extension GitHubClientTests {
    @Test
    func `A release's asset names are read one per line`() throws {
        let sut = makeSUT(command: releaseAssetsCommand, path: nil, output: success("nnex-arm64.tar.gz\nnnex-x86_64.tar.gz"))

        #expect(try sut.releaseAssetNames(in: "nikolainobadi/nnex-releases", tag: "1.3.0") == ["nnex-arm64.tar.gz", "nnex-x86_64.tar.gz"])
    }

    @Test
    func `A release without assets has an empty list`() throws {
        let sut = makeSUT(command: releaseAssetsCommand, path: nil, output: success(""))

        #expect(try sut.releaseAssetNames(in: "nikolainobadi/nnex-releases", tag: "1.3.0") == [])
    }

    @Test
    func `A missing release has no asset list`() throws {
        let sut = makeSUT(command: releaseAssetsCommand, path: nil, output: notFound)

        #expect(try sut.releaseAssetNames(in: "nikolainobadi/nnex-releases", tag: "1.3.0") == nil)
    }
}

// MARK: - Repository Owner
extension GitHubClientTests {
    @Test
    func `The owner of the project's GitHub repo is read`() throws {
        let sut = makeSUT(command: .repoOwner, path: projectPath, output: success("nikolainobadi"))

        #expect(try sut.repositoryOwner(at: projectPath) == "nikolainobadi")
    }

    @Test
    func `A failed owner lookup throws with gh's output`() throws {
        let sut = makeSUT(command: .repoOwner, path: projectPath, output: failure("no git remotes found"))

        #expect(throws: GitHubError.commandFailed(command: .repoOwner, exitCode: 1, output: "no git remotes found")) {
            try sut.repositoryOwner(at: projectPath)
        }
    }
}

// MARK: - Create Release
extension GitHubClientTests {
    @Test
    func `Creating a release returns its URL`() throws {
        let url = "https://github.com/nikolainobadi/nnex/releases/tag/1.3.0"
        let notesPath = "/Users/dev/nnex/.nnex/pending/release notes.md"
        let command = GitHubCommand.createRelease(tag: "1.3.0", title: "1.3.0", notesFilePath: notesPath)
        let sut = makeSUT(command: command, path: projectPath, output: success(url))

        #expect(try sut.createRelease(tag: "1.3.0", title: "1.3.0", notesFilePath: notesPath, at: projectPath) == url)
    }

    @Test
    func `A failed release creation throws commandFailed`() {
        let command = GitHubCommand.createRelease(tag: "1.3.0", title: "1.3.0", notesFilePath: "/notes.md")
        let sut = makeSUT(command: command, path: projectPath, output: failure("release already exists"))

        #expect(throws: GitHubError.commandFailed(command: command, exitCode: 1, output: "release already exists")) {
            try sut.createRelease(tag: "1.3.0", title: "1.3.0", notesFilePath: "/notes.md", at: projectPath)
        }
    }
}

// MARK: - Create Repo
extension GitHubClientTests {
    @Test
    func `Creating a repo passes the visibility and license`() {
        let command = GitHubCommand.createRepo(repo: "nikolainobadi/nnex-releases", visibility: .public, license: "mit")
        let sut = makeSUT(command: command, path: nil, output: success("https://github.com/nikolainobadi/nnex-releases"))

        #expect(throws: Never.self) {
            try sut.createRepo("nikolainobadi/nnex-releases", visibility: .public, license: "mit")
        }
    }

    @Test
    func `Creating a private repo without a license succeeds`() {
        let command = GitHubCommand.createRepo(repo: "nikolainobadi/GitHappens", visibility: .private, license: nil)
        let sut = makeSUT(command: command, path: nil, output: success("https://github.com/nikolainobadi/GitHappens"))

        #expect(throws: Never.self) {
            try sut.createRepo("nikolainobadi/GitHappens", visibility: .private, license: nil)
        }
    }

    @Test
    func `A failed repo creation throws commandFailed`() {
        let command = GitHubCommand.createRepo(repo: "nikolainobadi/nnex-releases", visibility: .public, license: "mit")
        let sut = makeSUT(command: command, path: nil, output: failure("name already exists on this account"))

        #expect(throws: GitHubError.commandFailed(command: command, exitCode: 1, output: "name already exists on this account")) {
            try sut.createRepo("nikolainobadi/nnex-releases", visibility: .public, license: "mit")
        }
    }

    @Test
    func `Creating a repo from a local source succeeds`() {
        let command = GitHubCommand.createRepoFromSource(repo: "nikolainobadi/GitHappens", visibility: .private, description: "", sourcePath: projectPath, remote: "origin")
        let sut = makeSUT(command: command, path: nil, output: success("https://github.com/nikolainobadi/GitHappens"))

        #expect(throws: Never.self) {
            try sut.createRepo("nikolainobadi/GitHappens", visibility: .private, description: "", sourcePath: projectPath, remote: "origin")
        }
    }

    @Test
    func `A failed repo creation from a local source throws commandFailed`() {
        let command = GitHubCommand.createRepoFromSource(repo: "nikolainobadi/GitHappens", visibility: .public, description: "", sourcePath: projectPath, remote: "origin")
        let sut = makeSUT(command: command, path: nil, output: failure("Unable to add remote \"origin\""))

        #expect(throws: GitHubError.commandFailed(command: command, exitCode: 1, output: "Unable to add remote \"origin\"")) {
            try sut.createRepo("nikolainobadi/GitHappens", visibility: .public, description: "", sourcePath: projectPath, remote: "origin")
        }
    }
}

// MARK: - Authenticated Login
extension GitHubClientTests {
    @Test
    func `The logged-in user's login is read and trimmed`() throws {
        let sut = makeSUT(command: loginCommand, path: nil, output: success("nikolainobadi\n"))

        #expect(try sut.authenticatedLogin() == "nikolainobadi")
    }

    @Test
    func `An empty login reads as nil`() throws {
        let sut = makeSUT(command: loginCommand, path: nil, output: success("  \n"))

        #expect(try sut.authenticatedLogin() == nil)
    }

    @Test
    func `A failed login lookup throws requestFailed`() {
        let sut = makeSUT(command: loginCommand, path: nil, output: failure("gh: Bad credentials (HTTP 401)"))

        #expect(throws: GitHubError.requestFailed(endpoint: "user", output: "gh: Bad credentials (HTTP 401)")) {
            try sut.authenticatedLogin()
        }
    }
}

// MARK: - Clone
extension GitHubClientTests {
    @Test
    func `A failed clone throws commandFailed`() {
        let command = GitHubCommand.cloneRepo(repo: "nikolainobadi/homebrew-nn", destinationPath: "/tmp/nnex-release/tap")
        let sut = makeSUT(command: command, path: nil, output: failure("Could not resolve to a Repository"))

        #expect(throws: GitHubError.commandFailed(command: command, exitCode: 1, output: "Could not resolve to a Repository")) {
            try sut.cloneRepo("nikolainobadi/homebrew-nn", into: "/tmp/nnex-release/tap")
        }
    }
}

// MARK: - Public Release
extension GitHubClientTests {
    @Test
    func `A release in another repo attaches every asset and returns its URL`() throws {
        let url = "https://github.com/nikolainobadi/nnex-releases/releases/tag/1.3.0"
        let assetPaths = ["/tmp/archives/nnex-arm64.tar.gz", "/tmp/archives/nnex-x86_64.tar.gz"]
        let command = GitHubCommand.createRemoteRelease(repo: "nikolainobadi/nnex-releases", tag: "1.3.0", title: "1.3.0", notesFilePath: "/tmp/notes.md", assetPaths: assetPaths)
        let sut = makeSUT(command: command, path: nil, output: success(url))

        #expect(try sut.createRelease(tag: "1.3.0", title: "1.3.0", notesFilePath: "/tmp/notes.md", assetPaths: assetPaths, in: "nikolainobadi/nnex-releases") == url)
    }

    @Test
    func `A failed asset upload throws commandFailed`() {
        let command = GitHubCommand.uploadReleaseAssets(repo: "nikolainobadi/nnex-releases", tag: "1.3.0", assetPaths: ["/tmp/archives/nnex-x86_64.tar.gz"])
        let sut = makeSUT(command: command, path: nil, output: failure("HTTP 422"))

        #expect(throws: GitHubError.commandFailed(command: command, exitCode: 1, output: "HTTP 422")) {
            try sut.uploadReleaseAssets(["/tmp/archives/nnex-x86_64.tar.gz"], tag: "1.3.0", in: "nikolainobadi/nnex-releases")
        }
    }

    @Test
    func `Downloading release assets saves them into the given folder`() {
        let sut = makeSUT(command: downloadAssetsCommand, path: nil, output: success(""))

        #expect(throws: Never.self) {
            try sut.downloadReleaseAssets(tag: "1.3.0", in: "nikolainobadi/nnex-releases", into: "/tmp/release-assets")
        }
    }

    @Test
    func `A failed asset download throws commandFailed`() {
        let sut = makeSUT(command: downloadAssetsCommand, path: nil, output: failure("release not found"))

        #expect(throws: GitHubError.commandFailed(command: downloadAssetsCommand, exitCode: 1, output: "release not found")) {
            try sut.downloadReleaseAssets(tag: "1.3.0", in: "nikolainobadi/nnex-releases", into: "/tmp/release-assets")
        }
    }
}

// MARK: - Helpers
private extension GitHubClientTests {
    var projectPath: String {
        return "/Users/dev/nnex"
    }

    var repoExistsCommand: GitHubCommand {
        return .apiRead(endpoint: "repos/nikolainobadi/nnex-releases", jq: ".full_name")
    }

    var loginCommand: GitHubCommand {
        return .apiRead(endpoint: "user", jq: ".login")
    }

    var latestReleaseCommand: GitHubCommand {
        return .apiRead(endpoint: "repos/nikolainobadi/nnex-releases/releases/latest", jq: ".tag_name")
    }

    var fileContentsCommand: GitHubCommand {
        return .apiReadRaw(endpoint: "repos/nikolainobadi/homebrew-nn/contents/Formula/nnex.rb")
    }

    var licenseCommand: GitHubCommand {
        return .apiRead(endpoint: "repos/nikolainobadi/nnex-releases/license", jq: ".license.spdx_id")
    }

    var releaseAssetsCommand: GitHubCommand {
        return .apiRead(endpoint: "repos/nikolainobadi/nnex-releases/releases/tags/1.3.0", jq: ".assets[].name")
    }

    var downloadAssetsCommand: GitHubCommand {
        return .downloadReleaseAssets(repo: "nikolainobadi/nnex-releases", tag: "1.3.0", destinationPath: "/tmp/release-assets")
    }

    var notFound: GitCommandOutput {
        return failure(#"{"message":"Not Found","status":"404"}gh: Not Found (HTTP 404)"#)
    }

    func success(_ output: String) -> GitCommandOutput {
        return .init(exitCode: 0, output: output)
    }

    func failure(_ output: String) -> GitCommandOutput {
        return .init(exitCode: 1, output: output)
    }
}

// MARK: - SUT
private extension GitHubClientTests {
    func makeSUT(command: GitHubCommand, path: String?, output: GitCommandOutput) -> GitHubClient {
        let runner = MockGitCommandRunner(gitResults: [], gitHubResults: [.init(command: command, path: path, output: output)])

        return .init(runner: runner)
    }
}
