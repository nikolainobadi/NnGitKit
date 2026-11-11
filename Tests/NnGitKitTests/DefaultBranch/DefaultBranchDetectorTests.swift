import Testing
import NnGitKit

struct DefaultBranchDetectorTests {
    @Test(arguments: DefaultBranchDetectorTests.examples)
    func `detect returns each example's result`(example: (remoteHeadBranches: [String: String], upstreamRemote: String?, configuredDefaultBranch: String?, localBranchNames: [String], expected: String?)) {
        let sut = makeSUT()

        #expect(sut.detect(remoteHeadBranches: example.remoteHeadBranches, upstreamRemote: example.upstreamRemote, configuredDefaultBranch: example.configuredDefaultBranch, localBranchNames: example.localBranchNames) == example.expected)
    }
}

// MARK: - Examples
private extension DefaultBranchDetectorTests {
    static let examples: [(remoteHeadBranches: [String: String], upstreamRemote: String?, configuredDefaultBranch: String?, localBranchNames: [String], expected: String?)] = [
        (remoteHeadBranches: ["origin": "origin/main"], upstreamRemote: nil, configuredDefaultBranch: nil, localBranchNames: ["main"], expected: "main"),
        (remoteHeadBranches: ["origin": "origin/main"], upstreamRemote: nil, configuredDefaultBranch: "trunk", localBranchNames: [], expected: "main"),
        (remoteHeadBranches: ["origin": "origin/main", "fork": "fork/develop"], upstreamRemote: "fork", configuredDefaultBranch: nil, localBranchNames: [], expected: "develop"),
        (remoteHeadBranches: ["origin": "origin/main", "fork": "fork/develop"], upstreamRemote: nil, configuredDefaultBranch: nil, localBranchNames: [], expected: "main"),
        (remoteHeadBranches: ["fork": "fork/develop", "mirror": "mirror/trunk"], upstreamRemote: nil, configuredDefaultBranch: nil, localBranchNames: [], expected: "develop"),
        (remoteHeadBranches: ["origin": "origin/main"], upstreamRemote: "fork", configuredDefaultBranch: nil, localBranchNames: [], expected: "main"),
        (remoteHeadBranches: [:], upstreamRemote: nil, configuredDefaultBranch: "trunk", localBranchNames: [], expected: "trunk"),
        (remoteHeadBranches: [:], upstreamRemote: nil, configuredDefaultBranch: nil, localBranchNames: ["dev", "main"], expected: "main"),
        (remoteHeadBranches: [:], upstreamRemote: nil, configuredDefaultBranch: nil, localBranchNames: ["master"], expected: "master"),
        (remoteHeadBranches: [:], upstreamRemote: nil, configuredDefaultBranch: nil, localBranchNames: ["dev"], expected: nil)
    ]
}

// MARK: - SUT
private extension DefaultBranchDetectorTests {
    func makeSUT() -> DefaultBranchDetector.Type {
        return DefaultBranchDetector.self
    }
}
