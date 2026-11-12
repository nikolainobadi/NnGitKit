public enum GitResetMode: Equatable, Sendable {
    case soft
    case hard
}

// MARK: - Flag
extension GitResetMode {
    var flag: String {
        switch self {
        case .soft:
            return "--soft"
        case .hard:
            return "--hard"
        }
    }
}
