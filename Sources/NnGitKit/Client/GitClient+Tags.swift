// MARK: - Tags
extension GitClient {
    public func tagNames(at path: String) throws -> [String] {
        return try lines(of: runExpectingSuccess(.tagList, at: path))
    }

    public func createTag(named name: String, at path: String) throws {
        try runExpectingSuccess(.createTag(name: name), at: path)
    }

    public func commit(ofTag name: String, at path: String) throws -> String? {
        let result = try runner.runGit(.revParseCommit(ref: "refs/tags/\(name)"), at: path)

        guard result.exitCode == 0 else {
            return nil
        }

        return trimmed(result.output)
    }
}
