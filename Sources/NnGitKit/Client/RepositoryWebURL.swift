import Foundation

public enum RepositoryWebURL {
    public static func make(remoteURL: String) -> String? {
        let location = remoteURL.contains("://") ? urlLocation(of: remoteURL) : scpLocation(of: remoteURL)

        guard let location, hostIsValid(location.host), let path = repositoryPath(from: location.path) else {
            return nil
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = location.host
        components.path = "/" + path

        return components.string
    }
}

// MARK: - Private Methods
private extension RepositoryWebURL {
    struct Location {
        let host: String
        let path: String
    }

    static let gitSuffix = ".git"

    static func urlLocation(of remoteURL: String) -> Location? {
        guard let components = URLComponents(string: remoteURL), let scheme = components.scheme?.lowercased(), let host = components.host else {
            return nil
        }

        guard scheme == "ssh" || (scheme == "https" && components.port == nil) else {
            return nil
        }

        return .init(host: host, path: components.path)
    }

    static func scpLocation(of remoteURL: String) -> Location? {
        guard let colon = remoteURL.firstIndex(of: ":") else {
            return nil
        }

        let authority = remoteURL[..<colon]

        guard !authority.contains("/") else {
            return nil
        }

        let host = authority.split(separator: "@").last.map(String.init) ?? ""

        return .init(host: host, path: String(remoteURL[remoteURL.index(after: colon)...]))
    }

    static func hostIsValid(_ host: String) -> Bool {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-"))

        return !host.isEmpty && host.unicodeScalars.allSatisfy(allowed.contains)
    }

    static func repositoryPath(from path: String) -> String? {
        var trimmedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if trimmedPath.hasSuffix(gitSuffix) {
            trimmedPath.removeLast(gitSuffix.count)
        }

        return trimmedPath.isEmpty ? nil : trimmedPath
    }
}
