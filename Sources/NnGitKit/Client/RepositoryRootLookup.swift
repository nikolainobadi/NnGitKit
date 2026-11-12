public enum RepositoryRootLookup: Sendable, Equatable {
    case found(path: String)
    case notFound(output: String)
}
