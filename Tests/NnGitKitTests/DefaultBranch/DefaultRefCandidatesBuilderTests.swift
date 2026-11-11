import Testing
import NnGitKit

struct DefaultRefCandidatesBuilderTests {
    @Test
    func `Remote refs named like a default branch are candidates, HEAD never`() {
        let refs = makeSUT().make(localBranchNames: [], remoteBranchNames: ["origin/HEAD", "origin/main", "origin/feature", "upstream/master"], remoteHeadBranches: [:], configuredDefaultBranch: nil)

        #expect(refs == ["origin/main", "upstream/master"])
    }

    @Test
    func `Remote HEAD targets and the configured default add names`() {
        let refs = makeSUT().make(localBranchNames: [], remoteBranchNames: ["origin/trunk", "origin/develop", "origin/feature"], remoteHeadBranches: ["origin": "origin/trunk"], configuredDefaultBranch: "develop")

        #expect(refs == ["origin/trunk", "origin/develop"])
    }

    @Test
    func `Local branches with a candidate name follow the remote refs`() {
        let refs = makeSUT().make(localBranchNames: ["feature", "main"], remoteBranchNames: ["origin/main"], remoteHeadBranches: [:], configuredDefaultBranch: nil)

        #expect(refs == ["origin/main", "main"])
    }
}

// MARK: - SUT
private extension DefaultRefCandidatesBuilderTests {
    func makeSUT() -> DefaultRefCandidatesBuilder.Type {
        return DefaultRefCandidatesBuilder.self
    }
}
