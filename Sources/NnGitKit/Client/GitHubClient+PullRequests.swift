// MARK: - Pull Requests
extension GitHubClient {
    public func openPullRequestURL(head: String, in repo: String) throws -> String? {
        let output = try runExpectingSuccess(.openPullRequestURLs(repo: repo, head: head), at: nil)

        return output.split(whereSeparator: \.isNewline).first.map(String.init)
    }

    public func pullRequest(number: Int, in repo: String) throws -> PullRequestDetails {
        let command = GitHubCommand.pullRequestDetails(repo: repo, number: number)
        let output = try runExpectingSuccess(command, at: nil)
        let fields = output.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)

        guard fields.count == Self.pullRequestFieldCount, !fields[0].isEmpty else {
            throw GitHubError.unexpectedOutput(command: command, output: output)
        }

        return .init(
            headBranch: fields[0],
            pullRequestIsOpen: fields[1] == Self.openPullRequestState,
            headIsInFork: fields[2] == Self.trueField
        )
    }

    public func createPullRequest(base: String, head: String, in repo: String, at path: String) throws -> String {
        let command = GitHubCommand.createPullRequest(repo: repo, base: base, head: head)
        let output = try runExpectingSuccess(command, at: path)

        guard let url = output.split(whereSeparator: \.isNewline).last.map(String.init), !url.isEmpty else {
            throw GitHubError.unexpectedOutput(command: command, output: output)
        }

        return url
    }
}

// MARK: - Private Methods
private extension GitHubClient {
    static let pullRequestFieldCount = 3
    static let openPullRequestState = "OPEN"
    static let trueField = "true"
}
