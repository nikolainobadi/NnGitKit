import Testing
import NnGitKit

struct CommandArgumentsTests {
    @Test
    func `Git commands run against the given repository`() {
        #expect(GitCommand.branchShowCurrent.arguments(at: "/Users/dev/nngit") == ["-C", "/Users/dev/nngit", "branch", "--show-current"])
    }

    @Test
    func `A remote's address is looked up by the remote's name`() {
        #expect(GitCommand.remoteGetURL(name: "fork").arguments(at: "/repo") == ["-C", "/repo", "remote", "get-url", "fork"])
    }

    @Test
    func `Ancestry is checked between the two given refs`() {
        let arguments = GitCommand.isAncestor(ancestor: "feature/login", descendant: "main").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "merge-base", "--is-ancestor", "feature/login", "main"])
    }

    @Test
    func `Commits behind are counted against the given branch's upstream`() {
        let arguments = GitCommand.revListCountBehindUpstream(branch: "feature/login").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "rev-list", "--count", "feature/login..feature/login@{upstream}"])
    }

    @Test
    func `Commits ahead are counted against the given branch's upstream`() {
        let arguments = GitCommand.revListCountAheadOfUpstream(branch: "HEAD").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "rev-list", "--count", "HEAD@{upstream}..HEAD"])
    }
}

// MARK: - New Branch
extension CommandArgumentsTests {
    @Test
    func `The git directory is read as an absolute path`() {
        #expect(GitCommand.revParseAbsoluteGitDir.arguments(at: "/repo") == ["-C", "/repo", "rev-parse", "--absolute-git-dir"])
    }

    @Test
    func `Every remote is fetched and pruned quietly`() {
        #expect(GitCommand.fetchAllPruned.arguments(at: "/repo") == ["-C", "/repo", "fetch", "--all", "--prune", "--quiet"])
    }

    @Test
    func `Upstream details are read as NUL-separated fields for the given branch`() {
        let arguments = GitCommand.upstreamDetails(branch: "feature/login").arguments(at: "/repo")

        #expect(arguments == [
            "-C", "/repo", "for-each-ref",
            "--format=%(upstream:short)%00%(upstream:remotename)%00%(upstream:remoteref)%00%(upstream:track)",
            "refs/heads/feature/login"
        ])
    }

    @Test
    func `A config value is read by key`() {
        let arguments = GitCommand.configGet(key: "githappens.defaultbranch").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "config", "--get", "githappens.defaultbranch"])
    }

    @Test
    func `A symbolic ref is read in its short form`() {
        let arguments = GitCommand.symbolicRefShort(ref: "refs/remotes/origin/HEAD").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD"])
    }

    @Test
    func `Commit summaries are logged one per line for the given range`() {
        let arguments = GitCommand.logOneline(range: "origin/main..main").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "log", "--oneline", "--no-decorate", "origin/main..main"])
    }

    @Test
    func `A new branch is created and switched to`() {
        let arguments = GitCommand.switchCreate(branch: "login-form").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "switch", "--create", "login-form"])
    }

    @Test
    func `A branch is forced to point at the given target`() {
        let arguments = GitCommand.branchForce(branch: "main", target: "origin/main").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "branch", "--force", "main", "origin/main"])
    }

    @Test
    func `A merge only fast-forwards to the given ref`() {
        let arguments = GitCommand.mergeFastForward(ref: "@{upstream}").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "merge", "--ff-only", "--quiet", "@{upstream}"])
    }

    @Test
    func `A push names both the source and the destination ref`() {
        let arguments = GitCommand.pushRefspec(remote: "origin", source: "main", destination: "refs/heads/main").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "push", "origin", "main:refs/heads/main"])
    }
}

// MARK: - New Push
extension CommandArgumentsTests {
    @Test
    func `A first push records the remote branch as the upstream`() {
        let arguments = GitCommand.pushSettingUpstream(remote: "origin", branch: "feature/login").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "push", "--set-upstream", "origin", "feature/login"])
    }

    @Test
    func `Setting a remote's HEAD names the branch directly`() {
        let arguments = GitCommand.remoteSetHead(remote: "origin", branch: "main").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "remote", "set-head", "origin", "main"])
    }

    @Test
    func `Commits are counted from the base to the tip`() {
        let arguments = GitCommand.revListCountRange(base: "HEAD", tip: "origin/main").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "rev-list", "--count", "HEAD..origin/main"])
    }
}

// MARK: - Branches and Worktrees
extension CommandArgumentsTests {
    @Test
    func `Local branch details are read as NUL-separated fields with full branch names`() {
        let arguments = GitCommand.localBranchDetails.arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "for-each-ref", "--format=%(refname:strip=2)%00%(worktreepath)%00%(upstream:short)%00%(upstream:track,nobracket)", "refs/heads"])
    }

    @Test
    func `Worktrees are listed as NUL-separated porcelain records`() {
        #expect(GitCommand.worktreeList.arguments(at: "/repo") == ["-C", "/repo", "worktree", "list", "--porcelain", "-z"])
    }

    @Test
    func `An existing branch is switched to by name`() {
        #expect(GitCommand.switchBranch(branch: "feature/login").arguments(at: "/repo") == ["-C", "/repo", "switch", "feature/login"])
    }

    @Test
    func `A remote branch is switched to through a new tracking branch`() {
        let arguments = GitCommand.switchTrack(remoteBranch: "origin/feature/login").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "switch", "--track", "origin/feature/login"])
    }

    @Test
    func `A branch is deleted whether or not git considers it merged`() {
        #expect(GitCommand.deleteBranchForce(branch: "feature/login").arguments(at: "/repo") == ["-C", "/repo", "branch", "-D", "feature/login"])
    }

    @Test
    func `A worktree is removed without force when nothing needs overriding`() {
        let arguments = GitCommand.worktreeRemove(path: "/repo-login", force: .none).arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "worktree", "remove", "/repo-login"])
    }

    @Test
    func `A worktree with changes is removed with one force flag`() {
        let arguments = GitCommand.worktreeRemove(path: "/repo-login", force: .discardChanges).arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "worktree", "remove", "--force", "/repo-login"])
    }

    @Test
    func `A locked worktree is removed with two force flags`() {
        let arguments = GitCommand.worktreeRemove(path: "/repo-login", force: .overrideLock).arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "worktree", "remove", "--force", "--force", "/repo-login"])
    }

    @Test
    func `Stale worktree records are pruned`() {
        #expect(GitCommand.worktreePrune.arguments(at: "/repo") == ["-C", "/repo", "worktree", "prune"])
    }

    @Test
    func `A worktree on a new branch starts from its base without tracking it`() {
        let arguments = GitCommand.worktreeAddNewBranch(path: "/repo/.worktrees/login", branch: "login", base: "origin/main").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "worktree", "add", "--quiet", "--no-track", "-b", "login", "/repo/.worktrees/login", "origin/main"])
    }

    @Test
    func `A worktree for an existing branch checks that branch out`() {
        let arguments = GitCommand.worktreeAdd(path: "/repo/.worktrees/login", branch: "login").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "worktree", "add", "--quiet", "/repo/.worktrees/login", "login"])
    }

    @Test
    func `A worktree for a remote branch creates a local branch that tracks it`() {
        let arguments = GitCommand.worktreeAddTracking(path: "/repo/.worktrees/login", branch: "login", remoteBranch: "origin/login").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "worktree", "add", "--quiet", "--track", "-b", "login", "/repo/.worktrees/login", "origin/login"])
    }

    @Test
    func `Merged branches are listed against the given ref`() {
        let arguments = GitCommand.mergedBranches(ref: "origin/main").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "for-each-ref", "--merged=origin/main", "--format=%(refname:strip=2)", "refs/heads"])
    }

    @Test
    func `A ref's tree is resolved quietly`() {
        #expect(GitCommand.revParseTree(ref: "origin/main").arguments(at: "/repo") == ["-C", "/repo", "rev-parse", "--verify", "--quiet", "origin/main^{tree}"])
    }

    @Test
    func `A trial merge writes only the resulting tree`() {
        let arguments = GitCommand.mergeTreeWriteTree(base: "origin/main", branch: "feature/login").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "merge-tree", "--write-tree", "origin/main", "feature/login"])
    }
}

// MARK: - GitHub
extension CommandArgumentsTests {
    @Test
    func `A repo is created with the given visibility and license`() {
        let arguments = GitHubCommand.createRepo(repo: "nikolainobadi/nngit", visibility: .public, license: "mit").arguments

        #expect(arguments == ["repo", "create", "nikolainobadi/nngit", "--public", "--license", "mit"])
    }

    @Test
    func `A repo without a license omits the license flag`() {
        let arguments = GitHubCommand.createRepo(repo: "nikolainobadi/GitHappens", visibility: .private, license: nil).arguments

        #expect(arguments == ["repo", "create", "nikolainobadi/GitHappens", "--private"])
    }

    @Test
    func `A repo created from a local source names its folder and remote`() {
        let arguments = GitHubCommand.createRepoFromSource(repo: "nikolainobadi/GitHappens", visibility: .private, description: "Git, but happier", sourcePath: "/Users/dev/GitHappens", remote: "origin").arguments

        #expect(arguments == ["repo", "create", "nikolainobadi/GitHappens", "--private", "--description", "Git, but happier", "--source", "/Users/dev/GitHappens", "--remote", "origin"])
    }

    @Test
    func `An empty description is still passed as its own argument`() {
        let arguments = GitHubCommand.createRepoFromSource(repo: "nikolainobadi/nngit", visibility: .public, description: "", sourcePath: "/Users/dev/nngit", remote: "origin").arguments

        #expect(arguments == ["repo", "create", "nikolainobadi/nngit", "--public", "--description", "", "--source", "/Users/dev/nngit", "--remote", "origin"])
    }
}

// MARK: - Discard
extension CommandArgumentsTests {
    @Test
    func `Collapsed status always lists untracked folders`() {
        #expect(GitCommand.statusPorcelainCollapsed.arguments(at: "/repo") == ["-C", "/repo", "status", "--porcelain=v2", "-z", "--untracked-files=normal"])
    }

    @Test(arguments: [
        (command: GitCommand.resetIndex, expected: ["reset", "--quiet", "HEAD"]),
        (command: .resetHardHead, expected: ["reset", "--hard", "--quiet", "HEAD"]),
        (command: .restoreWorktree, expected: ["checkout", "--", "."]),
        (command: .cleanUntracked, expected: ["clean", "-fd", "--quiet"])
    ])
    func `Whole-repository discards touch everything`(example: (command: GitCommand, expected: [String])) {
        #expect(example.command.arguments(at: "/repo") == ["-C", "/repo"] + example.expected)
    }

    @Test(arguments: [
        (command: GitCommand.resetIndexPaths(paths: ["*.txt", "old.txt"]), expected: ["reset", "--quiet", "HEAD", "--", "*.txt", "old.txt"]),
        (command: .restoreFromIndex(path: "*.txt"), expected: ["checkout", "--", "*.txt"]),
        (command: .restoreFromHead(path: "*.txt"), expected: ["checkout", "HEAD", "--", "*.txt"]),
        (command: .cleanPath(path: "*.txt"), expected: ["clean", "-fd", "--quiet", "--", "*.txt"])
    ])
    func `Single-path discards treat the path literally`(example: (command: GitCommand, expected: [String])) {
        #expect(example.command.arguments(at: "/repo") == ["-C", "/repo", "--literal-pathspecs"] + example.expected)
    }
}

// MARK: - Undo
extension CommandArgumentsTests {
    @Test
    func `Recent commits follow first parents only, with delimited fields`() {
        let arguments = GitCommand.logFirstParent(limit: 8).arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "log", "--first-parent", "--max-count=8", "--format=%H%x00%h%x00%s%x00%an%x00%ae%x00%ar%x00%P%x1e"])
    }

    @Test
    func `Activity logs non-merge commits with delimited records, dates, and line counts`() {
        let arguments = GitCommand.logActivity(refs: ["main", "HEAD"], since: "2026-11-05 00:00", author: nil).arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "log", "--no-merges", "--no-renames", "--since=2026-11-05 00:00", "--date=short-local", "--format=%x1e%h%x00%cd", "--numstat", "main", "HEAD", "--"])
    }

    @Test
    func `Commit changes log non-merge commits oldest first with subjects, line counts, and created and deleted files`() {
        let arguments = GitCommand.logCommitChanges(range: "origin/main..HEAD").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "log", "--no-merges", "--no-renames", "--reverse", "--format=%x1e%h%x00%cs%x00%s", "--numstat", "--summary", "origin/main..HEAD", "--"])
    }

    @Test
    func `Activity for one author matches the email as a fixed string`() {
        let arguments = GitCommand.logActivity(refs: ["HEAD"], since: "2026-11-07 00:00", author: "dev+git@example.com").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "log", "--no-merges", "--no-renames", "--since=2026-11-07 00:00", "--date=short-local", "--format=%x1e%h%x00%cd", "--numstat", "--fixed-strings", "--author=dev+git@example.com", "HEAD", "--"])
    }

    @Test(arguments: [
        (mode: GitResetMode.soft, flag: "--soft"),
        (mode: .hard, flag: "--hard")
    ])
    func `A reset moves to the exact target with the mode's flag`(example: (mode: GitResetMode, flag: String)) {
        let arguments = GitCommand.reset(mode: example.mode, target: "abc123").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "reset", example.flag, "--quiet", "abc123"])
    }

    @Test
    func `Paths a reset would restore come from comparing the target to HEAD without renames`() {
        let arguments = GitCommand.diffPathsMissingFromHead(target: "abc123").arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "diff", "--name-only", "-z", "--no-renames", "--diff-filter=D", "abc123", "HEAD", "--"])
    }

    @Test
    func `Unversioned paths include ignored files and treat paths literally`() {
        let arguments = GitCommand.lsFilesOthers(paths: ["*.txt", "d/x"]).arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "--literal-pathspecs", "ls-files", "--others", "-z", "--", "*.txt", "d/x"])
    }

    @Test
    func `Tracked paths are listed NUL-separated`() {
        #expect(GitCommand.lsFilesTracked.arguments(at: "/repo") == ["-C", "/repo", "ls-files", "-z"])
    }

    @Test
    func `Ignored tracked paths follow only the repository's gitignore files`() {
        let arguments = GitCommand.lsFilesIgnoredTracked.arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "ls-files", "-z", "--cached", "--ignored", "--exclude-per-directory=.gitignore"])
    }

    @Test
    func `Removing from the index keeps files on disk, recurses into folders, and treats paths literally`() {
        let arguments = GitCommand.removeCached(paths: ["build", "*.log"]).arguments(at: "/repo")

        #expect(arguments == ["-C", "/repo", "--literal-pathspecs", "rm", "--cached", "-r", "--quiet", "--", "build", "*.log"])
    }
}

// MARK: - New Commit
extension CommandArgumentsTests {
    @Test
    func `The index is snapshotted as a tree object`() {
        #expect(GitCommand.writeTree.arguments(at: "/repo") == ["-C", "/repo", "write-tree"])
    }

    @Test
    func `The index is restored from the given tree object`() {
        #expect(GitCommand.readTree(tree: "4b825dc").arguments(at: "/repo") == ["-C", "/repo", "read-tree", "4b825dc"])
    }

    @Test
    func `The staged diff is read without color or external diff tools`() {
        #expect(GitCommand.diffCached.arguments(at: "/repo") == ["-C", "/repo", "diff", "--cached", "--no-color", "--no-ext-diff"])
    }
}
