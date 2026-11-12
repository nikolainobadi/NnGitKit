import Testing
import NnGitKit

struct RemoteBranchRefTests {
    @Test(arguments: RemoteBranchRefTests.examples)
    func `branchName returns each example's result`(example: (remoteBranch: String, expected: String?)) {
        let sut = makeSUT()

        #expect(sut.branchName(of: example.remoteBranch) == example.expected)
    }
}

// MARK: - Examples
private extension RemoteBranchRefTests {
    static let examples: [(remoteBranch: String, expected: String?)] = [
        (remoteBranch: "origin/main", expected: "main"),
        (remoteBranch: "fork/feature/login", expected: "feature/login"),
        (remoteBranch: "origin/", expected: ""),
        (remoteBranch: "main", expected: nil)
    ]
}

// MARK: - SUT
private extension RemoteBranchRefTests {
    func makeSUT() -> RemoteBranchRef.Type {
        return RemoteBranchRef.self
    }
}
