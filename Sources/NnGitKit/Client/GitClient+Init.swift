// MARK: - Init
extension GitClient {
    public func initializeRepository(branch: String, at path: String) throws {
        try runExpectingSuccess(.initialize(branch: branch), at: path)
    }
}
