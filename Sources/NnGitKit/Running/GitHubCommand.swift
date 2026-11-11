public enum GitHubCommand: Equatable, Sendable {
    case apiRead(endpoint: String, jq: String)
    case apiReadRaw(endpoint: String)
    case repoOwner
    case repoNameWithOwner
    case repoVisibility(repo: String)
    case repoDefaultBranch(repo: String)
    case createRelease(tag: String, title: String, notesFilePath: String)
    case createRepo(repo: String, visibility: RepoVisibility, license: String?)
    case createRepoFromSource(repo: String, visibility: RepoVisibility, description: String, sourcePath: String, remote: String)
    case cloneRepo(repo: String, destinationPath: String)
    case createRemoteRelease(repo: String, tag: String, title: String, notesFilePath: String, assetPaths: [String])
    case uploadReleaseAssets(repo: String, tag: String, assetPaths: [String])
    case downloadReleaseAssets(repo: String, tag: String, destinationPath: String)
    case authStatus
    case openPullRequestURLs(repo: String, head: String)
    case pullRequestDetails(repo: String, number: Int)
    case createPullRequest(repo: String, base: String, head: String)
}

// MARK: - Arguments
extension GitHubCommand {
    public var arguments: [String] {
        switch self {
        case .apiRead(let endpoint, let jq):
            return ["api", endpoint, "--jq", jq]
        case .apiReadRaw(let endpoint):
            return ["api", endpoint, "-H", "Accept: application/vnd.github.raw"]
        case .repoOwner:
            return ["repo", "view", "--json", "owner", "--jq", ".owner.login"]
        case .repoNameWithOwner:
            return ["repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"]
        case .repoVisibility(let repo):
            return ["repo", "view", repo, "--json", "visibility", "--jq", ".visibility"]
        case .repoDefaultBranch(let repo):
            return ["repo", "view", repo, "--json", "defaultBranchRef", "--jq", ".defaultBranchRef.name"]
        case .createRelease(let tag, let title, let notesFilePath):
            return ["release", "create", tag, "--title", title, "--notes-file", notesFilePath]
        case .createRepo(let repo, let visibility, let license):
            let licenseArguments = license.map({ ["--license", $0] }) ?? []

            return ["repo", "create", repo, "--\(visibility.rawValue)"] + licenseArguments
        case .createRepoFromSource(let repo, let visibility, let description, let sourcePath, let remote):
            return ["repo", "create", repo, "--\(visibility.rawValue)", "--description", description, "--source", sourcePath, "--remote", remote]
        case .cloneRepo(let repo, let destinationPath):
            return ["repo", "clone", repo, destinationPath]
        case .createRemoteRelease(let repo, let tag, let title, let notesFilePath, let assetPaths):
            return ["release", "create", tag] + assetPaths + ["--repo", repo, "--title", title, "--notes-file", notesFilePath]
        case .uploadReleaseAssets(let repo, let tag, let assetPaths):
            return ["release", "upload", tag] + assetPaths + ["--repo", repo]
        case .downloadReleaseAssets(let repo, let tag, let destinationPath):
            return ["release", "download", tag, "--repo", repo, "--dir", destinationPath]
        case .authStatus:
            return ["auth", "status"]
        case .openPullRequestURLs(let repo, let head):
            return ["pr", "list", "--repo", repo, "--head", head, "--state", "open", "--json", "url", "--jq", ".[].url"]
        case .pullRequestDetails(let repo, let number):
            return ["pr", "view", String(number), "--repo", repo, "--json", "headRefName,state,isCrossRepository", "--jq", "[.headRefName,.state,.isCrossRepository]|@tsv"]
        case .createPullRequest(let repo, let base, let head):
            return ["pr", "create", "--repo", repo, "--base", base, "--head", head, "--fill"]
        }
    }
}
