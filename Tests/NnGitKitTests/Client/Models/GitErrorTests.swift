import Testing
import NnGitKit

struct GitErrorTests {
    @Test
    func `A failed command names the git command, its exit code, and its output`() {
        let error = GitError.commandFailed(command: .commit(message: "Release nnex 1.3.0"), exitCode: 1, output: "nothing to commit, working tree clean")

        #expect(error.localizedDescription == "`git commit --message Release nnex 1.3.0` failed with exit code 1.\nnothing to commit, working tree clean")
    }

    @Test
    func `A failed command without output omits the output line`() {
        let error = GitError.commandFailed(command: .addAll, exitCode: 128, output: "")

        #expect(error.localizedDescription == "`git add --all` failed with exit code 128.")
    }
}
