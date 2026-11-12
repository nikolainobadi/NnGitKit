// MARK: - Config
extension GitClient {
    public func configValue(for key: String, at path: String) throws -> String? {
        let result = try runner.runGit(.configGet(key: key), at: path)

        switch result.exitCode {
        case 0:
            let value = trimmed(result.output)

            return value.isEmpty ? nil : value
        case 1:
            return nil
        default:
            throw GitError.commandFailed(command: .configGet(key: key), exitCode: result.exitCode, output: result.output)
        }
    }
}
