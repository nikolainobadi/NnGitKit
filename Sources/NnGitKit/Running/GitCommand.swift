public enum GitCommand: Equatable, Sendable {
    case revParseTopLevel
    case revParseHead
    case revParseCommit(ref: String)
    case revListCount(since: String)
    case logMessages(since: String?, paths: [String])
    case checkIgnore(path: String)
    case branchShowCurrent
    case localBranchRefs
    case remoteBranchRefs
    case remote
    case remoteGetURL(name: String)
    case statusPorcelain
    case statusPorcelainPaths
    case tagList
    case addAll
    case commit(message: String)
    case commitAllowingEmpty(message: String)
    case initialize(branch: String)
    case createTag(name: String)
    case pushBranch(remote: String, branch: String)
    case pushTag(remote: String, tag: String)
    case pushHead(remote: String)
    case fetchAllTags
    case pullFastForward
    case revListCountBehindUpstream(branch: String)
    case revListCountAheadOfUpstream(branch: String)
    case isAncestor(ancestor: String, descendant: String)
    case revParseAbsoluteGitDir
    case fetchAllPruned
    case upstreamDetails(branch: String)
    case configGet(key: String)
    case symbolicRefShort(ref: String)
    case logOneline(range: String)
    case switchCreate(branch: String)
    case branchForce(branch: String, target: String)
    case mergeFastForward(ref: String)
    case pushRefspec(remote: String, source: String, destination: String)
    case pushSettingUpstream(remote: String, branch: String)
    case remoteSetHead(remote: String, branch: String)
    case revListCountRange(base: String, tip: String)
    case localBranchDetails
    case worktreeList
    case switchBranch(branch: String)
    case switchTrack(remoteBranch: String)
    case deleteBranchForce(branch: String)
    case worktreeRemove(path: String, force: WorktreeRemovalForce)
    case worktreePrune
    case worktreeAddNewBranch(path: String, branch: String, base: String)
    case worktreeAdd(path: String, branch: String)
    case worktreeAddTracking(path: String, branch: String, remoteBranch: String)
    case mergedBranches(ref: String)
    case revParseTree(ref: String)
    case mergeTreeWriteTree(base: String, branch: String)
    case statusPorcelainCollapsed
    case resetIndex
    case resetIndexPaths(paths: [String])
    case resetHardHead
    case restoreWorktree
    case restoreFromIndex(path: String)
    case restoreFromHead(path: String)
    case cleanUntracked
    case cleanPath(path: String)
    case logFirstParent(limit: Int)
    case logActivity(refs: [String], since: String, author: String?)
    case logCommitChanges(range: String)
    case reset(mode: GitResetMode, target: String)
    case diffPathsMissingFromHead(target: String)
    case lsFilesOthers(paths: [String])
    case lsFilesTracked
    case lsFilesIgnoredTracked
    case removeCached(paths: [String])
    case writeTree
    case readTree(tree: String)
    case diffCached
}

// MARK: - Arguments
extension GitCommand {
    public func arguments(at path: String) -> [String] {
        return ["-C", path] + commandArguments
    }
}

// MARK: - Helpers
extension GitCommand {
    var commandArguments: [String] {
        switch self {
        case .revParseTopLevel:
            return ["rev-parse", "--show-toplevel"]
        case .revParseHead:
            return ["rev-parse", "HEAD"]
        case .revParseCommit(let ref):
            return ["rev-parse", "--verify", "--quiet", "\(ref)^{commit}"]
        case .revListCount(let since):
            return ["rev-list", "--count", "\(since)..HEAD"]
        case .logMessages(let since, let paths):
            let range = since.map({ "\($0)..HEAD" }) ?? "HEAD"
            let pathspecs = paths.isEmpty ? [] : ["--"] + paths

            return ["log", "--no-merges", "--format=%B%x1e", range] + pathspecs
        case .checkIgnore(let path):
            return ["check-ignore", "--quiet", path]
        case .branchShowCurrent:
            return ["branch", "--show-current"]
        case .localBranchRefs:
            return ["for-each-ref", "--format=%(refname:strip=2)", "refs/heads"]
        case .remoteBranchRefs:
            return ["for-each-ref", "--format=%(refname:strip=2)", "refs/remotes"]
        case .remote:
            return ["remote"]
        case .remoteGetURL(let name):
            return ["remote", "get-url", name]
        case .statusPorcelain:
            return ["status", "--porcelain"]
        case .statusPorcelainPaths:
            return ["status", "--porcelain=v2", "-z", "--untracked-files=all"]
        case .tagList:
            return ["tag", "--list"]
        case .addAll:
            return ["add", "--all"]
        case .commit(let message):
            return ["commit", "--message", message]
        case .commitAllowingEmpty(let message):
            return ["commit", "--allow-empty", "--message", message]
        case .initialize(let branch):
            return ["init", "--initial-branch", branch]
        case .createTag(let name):
            return ["tag", name]
        case .pushBranch(let remote, let branch):
            return ["push", remote, branch]
        case .pushTag(let remote, let tag):
            return ["push", remote, "refs/tags/\(tag)"]
        case .pushHead(let remote):
            return ["push", remote, "HEAD"]
        case .fetchAllTags:
            return ["fetch", "--all", "--tags", "--quiet"]
        case .pullFastForward:
            return ["pull", "--ff-only", "--quiet"]
        case .revListCountBehindUpstream(let branch):
            return ["rev-list", "--count", "\(branch)..\(branch)@{upstream}"]
        case .revListCountAheadOfUpstream(let branch):
            return ["rev-list", "--count", "\(branch)@{upstream}..\(branch)"]
        case .isAncestor(let ancestor, let descendant):
            return ["merge-base", "--is-ancestor", ancestor, descendant]
        case .revParseAbsoluteGitDir:
            return ["rev-parse", "--absolute-git-dir"]
        case .fetchAllPruned:
            return ["fetch", "--all", "--prune", "--quiet"]
        case .upstreamDetails(let branch):
            return ["for-each-ref", "--format=%(upstream:short)%00%(upstream:remotename)%00%(upstream:remoteref)%00%(upstream:track)", "refs/heads/\(branch)"]
        case .configGet(let key):
            return ["config", "--get", key]
        case .symbolicRefShort(let ref):
            return ["symbolic-ref", "--quiet", "--short", ref]
        case .logOneline(let range):
            return ["log", "--oneline", "--no-decorate", range]
        case .switchCreate(let branch):
            return ["switch", "--create", branch]
        case .branchForce(let branch, let target):
            return ["branch", "--force", branch, target]
        case .mergeFastForward(let ref):
            return ["merge", "--ff-only", "--quiet", ref]
        case .pushRefspec(let remote, let source, let destination):
            return ["push", remote, "\(source):\(destination)"]
        case .pushSettingUpstream(let remote, let branch):
            return ["push", "--set-upstream", remote, branch]
        case .remoteSetHead(let remote, let branch):
            return ["remote", "set-head", remote, branch]
        case .revListCountRange(let base, let tip):
            return ["rev-list", "--count", "\(base)..\(tip)"]
        case .localBranchDetails:
            return ["for-each-ref", "--format=%(refname:strip=2)%00%(worktreepath)%00%(upstream:short)%00%(upstream:track,nobracket)", "refs/heads"]
        case .worktreeList:
            return ["worktree", "list", "--porcelain", "-z"]
        case .switchBranch(let branch):
            return ["switch", branch]
        case .switchTrack(let remoteBranch):
            return ["switch", "--track", remoteBranch]
        case .deleteBranchForce(let branch):
            return ["branch", "-D", branch]
        case .worktreeRemove(let path, let force):
            return ["worktree", "remove"] + force.flags + [path]
        case .worktreePrune:
            return ["worktree", "prune"]
        case .worktreeAddNewBranch(let path, let branch, let base):
            return ["worktree", "add", "--quiet", "--no-track", "-b", branch, path, base]
        case .worktreeAdd(let path, let branch):
            return ["worktree", "add", "--quiet", path, branch]
        case .worktreeAddTracking(let path, let branch, let remoteBranch):
            return ["worktree", "add", "--quiet", "--track", "-b", branch, path, remoteBranch]
        case .mergedBranches(let ref):
            return ["for-each-ref", "--merged=\(ref)", "--format=%(refname:strip=2)", "refs/heads"]
        case .revParseTree(let ref):
            return ["rev-parse", "--verify", "--quiet", "\(ref)^{tree}"]
        case .mergeTreeWriteTree(let base, let branch):
            return ["merge-tree", "--write-tree", base, branch]
        case .statusPorcelainCollapsed:
            return ["status", "--porcelain=v2", "-z", "--untracked-files=normal"]
        case .resetIndex:
            return ["reset", "--quiet", "HEAD"]
        case .resetIndexPaths(let paths):
            return ["--literal-pathspecs", "reset", "--quiet", "HEAD", "--"] + paths
        case .resetHardHead:
            return ["reset", "--hard", "--quiet", "HEAD"]
        case .restoreWorktree:
            return ["checkout", "--", "."]
        case .restoreFromIndex(let path):
            return ["--literal-pathspecs", "checkout", "--", path]
        case .restoreFromHead(let path):
            return ["--literal-pathspecs", "checkout", "HEAD", "--", path]
        case .cleanUntracked:
            return ["clean", "-fd", "--quiet"]
        case .cleanPath(let path):
            return ["--literal-pathspecs", "clean", "-fd", "--quiet", "--", path]
        case .logFirstParent(let limit):
            return ["log", "--first-parent", "--max-count=\(limit)", "--format=%H%x00%h%x00%s%x00%an%x00%ae%x00%ar%x00%P%x1e"]
        case .logActivity(let refs, let since, let author):
            let authorFilter = author.map({ ["--fixed-strings", "--author=\($0)"] }) ?? []

            return ["log", "--no-merges", "--no-renames", "--since=\(since)", "--date=short-local", "--format=%x1e%h%x00%cd", "--numstat"] + authorFilter + refs + ["--"]
        case .logCommitChanges(let range):
            return ["log", "--no-merges", "--no-renames", "--reverse", "--format=%x1e%h%x00%cs%x00%s", "--numstat", "--summary", range, "--"]
        case .reset(let mode, let target):
            return ["reset", mode.flag, "--quiet", target]
        case .diffPathsMissingFromHead(let target):
            return ["diff", "--name-only", "-z", "--no-renames", "--diff-filter=D", target, "HEAD", "--"]
        case .lsFilesOthers(let paths):
            return ["--literal-pathspecs", "ls-files", "--others", "-z", "--"] + paths
        case .lsFilesTracked:
            return ["ls-files", "-z"]
        case .lsFilesIgnoredTracked:
            return ["ls-files", "-z", "--cached", "--ignored", "--exclude-per-directory=.gitignore"]
        case .removeCached(let paths):
            return ["--literal-pathspecs", "rm", "--cached", "-r", "--quiet", "--"] + paths
        case .writeTree:
            return ["write-tree"]
        case .readTree(let tree):
            return ["read-tree", tree]
        case .diffCached:
            return ["diff", "--cached", "--no-color", "--no-ext-diff"]
        }
    }
}
