import Testing
import NnGitKit

struct RepositoryWebURLTests {
    @Test(arguments: RepositoryWebURLTests.convertibleExamples)
    func `Remotes with a web page convert to its https address`(example: (remoteURL: String, expected: String)) {
        let sut = makeSUT()

        #expect(sut.make(remoteURL: example.remoteURL) == example.expected)
    }

    @Test(arguments: RepositoryWebURLTests.unsupportedExamples)
    func `Remotes without a supported web page have no address`(remoteURL: String) {
        let sut = makeSUT()

        #expect(sut.make(remoteURL: remoteURL) == nil)
    }

    @Test
    func `Credentials in a remote never reach the web address`() throws {
        let sut = makeSUT()

        let webURL = try #require(sut.make(remoteURL: "https://user:secret-token@github.com/owner/repo.git"))

        #expect(!webURL.contains("secret-token"))
        #expect(!webURL.contains("user"))
    }
}

// MARK: - Examples
private extension RepositoryWebURLTests {
    static let convertibleExamples: [(remoteURL: String, expected: String)] = [
        (remoteURL: "https://github.com/owner/repo.git", expected: "https://github.com/owner/repo"),
        (remoteURL: "https://github.com/owner/repo", expected: "https://github.com/owner/repo"),
        (remoteURL: "https://github.com/owner/repo/", expected: "https://github.com/owner/repo"),
        (remoteURL: "https://user:token@github.com/owner/repo.git", expected: "https://github.com/owner/repo"),
        (remoteURL: "git@github.com:owner/repo.git", expected: "https://github.com/owner/repo"),
        (remoteURL: "git@github.com:owner/repo", expected: "https://github.com/owner/repo"),
        (remoteURL: "github.com:owner/repo", expected: "https://github.com/owner/repo"),
        (remoteURL: "ssh://git@github.com/owner/repo.git", expected: "https://github.com/owner/repo"),
        (remoteURL: "ssh://git@github.com:2222/owner/repo.git", expected: "https://github.com/owner/repo"),
        (remoteURL: "git@gitlab.com:owner/repo.git", expected: "https://gitlab.com/owner/repo")
    ]

    static let unsupportedExamples = [
        "git://github.com/owner/repo.git",
        "http://git.local/owner/repo",
        "https://git.local:8443/owner/repo.git",
        "/path/to/repo.git",
        "../repo",
        "./a:b",
        "file:///tmp/repo.git",
        "https://github.com/",
        "git@github.com:",
        "git@[::1]:owner/repo.git",
        ""
    ]
}

// MARK: - SUT
private extension RepositoryWebURLTests {
    func makeSUT() -> RepositoryWebURL.Type {
        return RepositoryWebURL.self
    }
}
