// MARK: - Stash
extension GitClient {
    /// One line per stash, as `git stash list` prints it (such as `stash@{0}: WIP on main: …`).
    public func stashEntries(at path: String) throws -> [String] {
        return try lines(of: runExpectingSuccess(.stashList, at: path))
    }
}
