public enum FetchResult: Sendable, Equatable {
    case fetched
    case failed(output: String)
}
