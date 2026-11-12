// MARK: - Releases
extension GitHubClient {
    public func latestReleaseTag(in repo: String) throws -> String? {
        let endpoint = "repos/\(repo)/releases/latest"

        return try readAPI(.apiRead(endpoint: endpoint, jq: ".tag_name"), endpoint: endpoint).flatMap(nonEmpty)
    }

    public func releaseAssetNames(in repo: String, tag: String) throws -> [String]? {
        let endpoint = "repos/\(repo)/releases/tags/\(tag)"

        return try readAPI(.apiRead(endpoint: endpoint, jq: ".assets[].name"), endpoint: endpoint).map({ output in
            return output.split(whereSeparator: \.isNewline).map(String.init)
        })
    }

    public func createRelease(tag: String, title: String, notesFilePath: String, at path: String) throws -> String {
        return try runExpectingSuccess(.createRelease(tag: tag, title: title, notesFilePath: notesFilePath), at: path)
    }

    public func createRelease(tag: String, title: String, notesFilePath: String, assetPaths: [String], in repo: String) throws -> String {
        return try runExpectingSuccess(.createRemoteRelease(repo: repo, tag: tag, title: title, notesFilePath: notesFilePath, assetPaths: assetPaths), at: nil)
    }

    public func uploadReleaseAssets(_ assetPaths: [String], tag: String, in repo: String) throws {
        try runExpectingSuccess(.uploadReleaseAssets(repo: repo, tag: tag, assetPaths: assetPaths), at: nil)
    }

    public func downloadReleaseAssets(tag: String, in repo: String, into destinationPath: String) throws {
        try runExpectingSuccess(.downloadReleaseAssets(repo: repo, tag: tag, destinationPath: destinationPath), at: nil)
    }
}
