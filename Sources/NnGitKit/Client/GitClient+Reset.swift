// MARK: - Reset
extension GitClient {
    public func reset(to target: String, mode: GitResetMode, at path: String) throws {
        try runExpectingSuccess(.reset(mode: mode, target: target), at: path)
    }
}
