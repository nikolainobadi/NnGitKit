import Testing
import NnGitKit
import NnGitTesting

struct GitHubClientPullRequestsTests {
    @Test
    func `A branch with no open pull request has no address`() throws {
        let sut = makeSUT(command: listCommand, path: nil, output: success(""))

        #expect(try sut.openPullRequestURL(head: "feature", in: repo) == nil)
    }

    @Test
    func `A branch's open pull request address is read`() throws {
        let sut = makeSUT(command: listCommand, path: nil, output: success("https://github.com/owner/project/pull/2\n"))

        #expect(try sut.openPullRequestURL(head: "feature", in: repo) == "https://github.com/owner/project/pull/2")
    }

    @Test
    func `The first of several open pull requests is used`() throws {
        let sut = makeSUT(command: listCommand, path: nil, output: success("https://github.com/owner/project/pull/2\nhttps://github.com/owner/project/pull/3\n"))

        #expect(try sut.openPullRequestURL(head: "feature", in: repo) == "https://github.com/owner/project/pull/2")
    }

    @Test
    func `A failed pull request list throws with gh's output`() {
        let sut = makeSUT(command: listCommand, path: nil, output: failure("HTTP 403"))

        #expect(throws: GitHubError.commandFailed(command: listCommand, exitCode: 1, output: "HTTP 403")) {
            try sut.openPullRequestURL(head: "feature", in: repo)
        }
    }
}

// MARK: - Details
extension GitHubClientPullRequestsTests {
    @Test
    func `An open pull request's details are read`() throws {
        let sut = makeSUT(command: detailsCommand, path: nil, output: success("stacked\tOPEN\tfalse\n"))

        #expect(try sut.pullRequest(number: 12, in: repo) == .init(headBranch: "stacked", pullRequestIsOpen: true, headIsInFork: false))
    }

    @Test
    func `A merged pull request isn't open`() throws {
        let sut = makeSUT(command: detailsCommand, path: nil, output: success("stacked\tMERGED\tfalse\n"))

        #expect(try sut.pullRequest(number: 12, in: repo).pullRequestIsOpen == false)
    }

    @Test
    func `A closed pull request isn't open`() throws {
        let sut = makeSUT(command: detailsCommand, path: nil, output: success("stacked\tCLOSED\tfalse\n"))

        #expect(try sut.pullRequest(number: 12, in: repo).pullRequestIsOpen == false)
    }

    @Test
    func `A pull request from a fork says so`() throws {
        let sut = makeSUT(command: detailsCommand, path: nil, output: success("stacked\tOPEN\ttrue\n"))

        #expect(try sut.pullRequest(number: 12, in: repo).headIsInFork)
    }

    @Test
    func `Details in an unexpected shape throw`() {
        let sut = makeSUT(command: detailsCommand, path: nil, output: success("stacked OPEN"))

        #expect(throws: GitHubError.unexpectedOutput(command: detailsCommand, output: "stacked OPEN")) {
            try sut.pullRequest(number: 12, in: repo)
        }
    }

    @Test
    func `A pull request GitHub can't find throws with gh's output`() {
        let sut = makeSUT(command: detailsCommand, path: nil, output: failure("GraphQL: Could not resolve to a PullRequest"))

        #expect(throws: GitHubError.commandFailed(command: detailsCommand, exitCode: 1, output: "GraphQL: Could not resolve to a PullRequest")) {
            try sut.pullRequest(number: 12, in: repo)
        }
    }
}

// MARK: - Create
extension GitHubClientPullRequestsTests {
    @Test
    func `Creating returns the new pull request's address`() throws {
        let sut = makeSUT(command: createCommand, path: projectPath, output: success("https://github.com/owner/project/pull/7\n"))

        #expect(try sut.createPullRequest(base: "main", head: "feature", in: repo, at: projectPath) == "https://github.com/owner/project/pull/7")
    }

    @Test
    func `A warning before the address is ignored`() throws {
        let sut = makeSUT(command: createCommand, path: projectPath, output: success("Warning: 1 uncommitted change\nhttps://github.com/owner/project/pull/7\n"))

        #expect(try sut.createPullRequest(base: "main", head: "feature", in: repo, at: projectPath) == "https://github.com/owner/project/pull/7")
    }

    @Test
    func `Creating with no output throws`() {
        let sut = makeSUT(command: createCommand, path: projectPath, output: success(""))

        #expect(throws: GitHubError.unexpectedOutput(command: createCommand, output: "")) {
            try sut.createPullRequest(base: "main", head: "feature", in: repo, at: projectPath)
        }
    }

    @Test
    func `A failed create throws with gh's output`() {
        let sut = makeSUT(command: createCommand, path: projectPath, output: failure("No commits between main and feature"))

        #expect(throws: GitHubError.commandFailed(command: createCommand, exitCode: 1, output: "No commits between main and feature")) {
            try sut.createPullRequest(base: "main", head: "feature", in: repo, at: projectPath)
        }
    }
}

// MARK: - Arguments
extension GitHubClientPullRequestsTests {
    @Test
    func `The open pull request list is limited to the head branch and open state`() {
        #expect(listCommand.arguments == ["pr", "list", "--repo", repo, "--head", "feature", "--state", "open", "--json", "url", "--jq", ".[].url"])
    }

    @Test
    func `Pull request details ask for the head, state, and fork fields as tab-separated values`() {
        #expect(detailsCommand.arguments == ["pr", "view", "12", "--repo", repo, "--json", "headRefName,state,isCrossRepository", "--jq", "[.headRefName,.state,.isCrossRepository]|@tsv"])
    }

    @Test
    func `Creating names the repository, base, and head, and fills from commits`() {
        #expect(createCommand.arguments == ["pr", "create", "--repo", repo, "--base", "main", "--head", "feature", "--fill"])
    }
}

// MARK: - Helpers
private extension GitHubClientPullRequestsTests {
    var repo: String {
        return "https://github.com/owner/project"
    }

    var projectPath: String {
        return "/Users/dev/project"
    }

    var listCommand: GitHubCommand {
        return .openPullRequestURLs(repo: repo, head: "feature")
    }

    var detailsCommand: GitHubCommand {
        return .pullRequestDetails(repo: repo, number: 12)
    }

    var createCommand: GitHubCommand {
        return .createPullRequest(repo: repo, base: "main", head: "feature")
    }

    func success(_ output: String) -> GitCommandOutput {
        return .init(exitCode: 0, output: output)
    }

    func failure(_ output: String) -> GitCommandOutput {
        return .init(exitCode: 1, output: output)
    }
}

// MARK: - SUT
private extension GitHubClientPullRequestsTests {
    func makeSUT(command: GitHubCommand, path: String?, output: GitCommandOutput) -> GitHubClient {
        let runner = MockGitCommandRunner(gitResults: [], gitHubResults: [.init(command: command, path: path, output: output)])

        return .init(runner: runner)
    }
}
