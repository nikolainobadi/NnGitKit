import Testing
import NnGitKit

struct DefaultBranchRefDetectorTests {
    @Test(arguments: DefaultBranchRefDetectorTests.examples)
    func `detect returns each example's result`(example: (defaultBranch: String, remoteBranchNames: [String], expected: String?)) {
        let sut = makeSUT()

        #expect(sut.detect(defaultBranch: example.defaultBranch, remoteBranchNames: example.remoteBranchNames) == example.expected)
    }
}

// MARK: - Examples
private extension DefaultBranchRefDetectorTests {
    static let examples: [(defaultBranch: String, remoteBranchNames: [String], expected: String?)] = [
        (defaultBranch: "main", remoteBranchNames: ["fork/main", "origin/main"], expected: "origin/main"),
        (defaultBranch: "main", remoteBranchNames: ["upstream/main", "fork/main"], expected: "fork/main"),
        (defaultBranch: "develop", remoteBranchNames: ["origin/main"], expected: nil),
        (defaultBranch: "release/2.0", remoteBranchNames: ["origin/HEAD", "origin/release/2.0"], expected: "origin/release/2.0"),
        (defaultBranch: "main", remoteBranchNames: ["origin/feature/main"], expected: nil)
    ]
}

// MARK: - SUT
private extension DefaultBranchRefDetectorTests {
    func makeSUT() -> DefaultBranchRefDetector.Type {
        return DefaultBranchRefDetector.self
    }
}
