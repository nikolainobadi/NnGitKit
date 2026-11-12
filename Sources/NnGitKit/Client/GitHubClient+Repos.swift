// MARK: - Repos
extension GitHubClient {
    public func isAuthenticated() throws -> Bool {
        return try runner.runGitHub(.authStatus, at: nil).exitCode == 0
    }

    public func authenticatedLogin() throws -> String? {
        let endpoint = "user"

        return try readAPI(.apiRead(endpoint: endpoint, jq: ".login"), endpoint: endpoint).flatMap(nonEmpty)
    }

    public func repoExists(_ repo: String) throws -> Bool {
        let endpoint = "repos/\(repo)"

        return try readAPI(.apiRead(endpoint: endpoint, jq: ".full_name"), endpoint: endpoint) != nil
    }

    public func repositoryOwner(at path: String) throws -> String? {
        return nonEmpty(try runExpectingSuccess(.repoOwner, at: path))
    }

    public func repositoryNameWithOwner(at path: String) throws -> String? {
        let result = try runner.runGitHub(.repoNameWithOwner, at: path)

        guard result.exitCode == 0 else {
            return nil
        }

        return nonEmpty(result.output)
    }

    public func repositoryVisibility(of repo: String) throws -> RepoVisibility {
        let output = try runExpectingSuccess(.repoVisibility(repo: repo), at: nil)

        guard let visibility = RepoVisibility(rawValue: output.lowercased()) else {
            throw GitHubError.unexpectedOutput(command: .repoVisibility(repo: repo), output: output)
        }

        return visibility
    }

    public func defaultBranch(of repo: String) throws -> String {
        let command = GitHubCommand.repoDefaultBranch(repo: repo)

        guard let branch = nonEmpty(try runExpectingSuccess(command, at: nil)) else {
            throw GitHubError.unexpectedOutput(command: command, output: "")
        }

        return branch
    }

    public func fileContents(atPath path: String, in repo: String) throws -> String? {
        let endpoint = "repos/\(repo)/contents/\(path)"

        return try readAPI(.apiReadRaw(endpoint: endpoint), endpoint: endpoint)
    }

    public func licenseSPDX(in repo: String) throws -> String? {
        let endpoint = "repos/\(repo)/license"

        guard let spdx = try readAPI(.apiRead(endpoint: endpoint, jq: ".license.spdx_id"), endpoint: endpoint).flatMap(nonEmpty) else {
            return nil
        }

        return spdx == "NOASSERTION" ? nil : spdx
    }

    public func createRepo(_ repo: String, visibility: RepoVisibility, license: String?) throws {
        try runExpectingSuccess(.createRepo(repo: repo, visibility: visibility, license: license), at: nil)
    }

    public func createRepo(_ repo: String, visibility: RepoVisibility, description: String, sourcePath: String, remote: String) throws {
        try runExpectingSuccess(.createRepoFromSource(repo: repo, visibility: visibility, description: description, sourcePath: sourcePath, remote: remote), at: nil)
    }

    public func cloneRepo(_ repo: String, into destinationPath: String) throws {
        try runExpectingSuccess(.cloneRepo(repo: repo, destinationPath: destinationPath), at: nil)
    }
}
