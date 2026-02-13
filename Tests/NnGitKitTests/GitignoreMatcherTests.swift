//
//  GitignoreMatcherTests.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 2/12/26.
//

import Testing
import GitCommandGen

struct GitignoreMatcherTests {
    @Test("Empty patterns ignore nothing")
    func emptyPatterns() {
        let matcher = GitignoreMatcher(patterns: [])
        #expect(!matcher.isIgnored("file.txt"))
    }

    @Test("Blank lines and comments are skipped")
    func blankAndCommentLines() {
        let matcher = GitignoreMatcher(patterns: ["", "# this is a comment", "   "])
        #expect(!matcher.isIgnored("file.txt"))
    }

    @Test("Simple filename pattern matches at any depth")
    func simpleFilenameAnyDepth() {
        let matcher = GitignoreMatcher(patterns: ["*.log"])
        #expect(matcher.isIgnored("debug.log"))
        #expect(matcher.isIgnored("src/debug.log"))
        #expect(matcher.isIgnored("a/b/c/debug.log"))
        #expect(!matcher.isIgnored("debug.txt"))
    }

    @Test("Directory-only pattern with trailing slash")
    func directoryOnlyPattern() {
        let matcher = GitignoreMatcher(patterns: ["build/"])
        #expect(matcher.isIgnored("build", isDirectory: true))
        #expect(!matcher.isIgnored("build", isDirectory: false))
        #expect(matcher.isIgnored("src/build", isDirectory: true))
    }

    @Test("Anchored pattern with leading slash")
    func anchoredLeadingSlash() {
        let matcher = GitignoreMatcher(patterns: ["/TODO"])
        #expect(matcher.isIgnored("TODO"))
        #expect(!matcher.isIgnored("src/TODO"))
    }

    @Test("Negation re-includes a file")
    func negationReIncludes() {
        let matcher = GitignoreMatcher(patterns: ["*.log", "!important.log"])
        #expect(matcher.isIgnored("debug.log"))
        #expect(!matcher.isIgnored("important.log"))
    }

    @Test("Last match wins with multiple negations")
    func lastMatchWins() {
        let matcher = GitignoreMatcher(patterns: ["*.log", "!important.log", "important.log"])
        #expect(matcher.isIgnored("important.log"))
    }

    @Test("Single star does not cross path separators")
    func singleStarNoCrossing() {
        let matcher = GitignoreMatcher(patterns: ["doc/*.txt"])
        #expect(matcher.isIgnored("doc/notes.txt"))
        #expect(!matcher.isIgnored("doc/sub/notes.txt"))
    }

    @Test("Question mark matches single non-separator character")
    func questionMarkSingleChar() {
        let matcher = GitignoreMatcher(patterns: ["file?.txt"])
        #expect(matcher.isIgnored("fileA.txt"))
        #expect(matcher.isIgnored("file1.txt"))
        #expect(!matcher.isIgnored("file10.txt"))
        #expect(!matcher.isIgnored("file/.txt"))
    }

    @Test("Leading double star matches at any depth")
    func leadingDoubleStar() {
        let matcher = GitignoreMatcher(patterns: ["**/logs"])
        #expect(matcher.isIgnored("logs"))
        #expect(matcher.isIgnored("src/logs"))
        #expect(matcher.isIgnored("a/b/logs"))
    }

    @Test("Trailing double star matches everything inside")
    func trailingDoubleStar() {
        let matcher = GitignoreMatcher(patterns: ["logs/**"])
        #expect(matcher.isIgnored("logs/debug.log"))
        #expect(matcher.isIgnored("logs/a/b/c.log"))
        #expect(!matcher.isIgnored("src/logs/debug.log"))
    }

    @Test("Middle double star matches zero or more directories")
    func middleDoubleStar() {
        let matcher = GitignoreMatcher(patterns: ["a/**/b"])
        #expect(matcher.isIgnored("a/b"))
        #expect(matcher.isIgnored("a/x/b"))
        #expect(matcher.isIgnored("a/x/y/b"))
        #expect(!matcher.isIgnored("c/a/b"))
    }

    @Test("Character range [abc] matches single character")
    func characterRange() {
        let matcher = GitignoreMatcher(patterns: ["file[abc].txt"])
        #expect(matcher.isIgnored("filea.txt"))
        #expect(matcher.isIgnored("fileb.txt"))
        #expect(!matcher.isIgnored("filed.txt"))
    }

    @Test("Negated character range [!abc] matches non-listed characters")
    func negatedCharacterRange() {
        let matcher = GitignoreMatcher(patterns: ["file[!abc].txt"])
        #expect(!matcher.isIgnored("filea.txt"))
        #expect(matcher.isIgnored("filed.txt"))
        #expect(matcher.isIgnored("filex.txt"))
    }

    @Test("Character range [a-z] matches range")
    func characterRangeHyphen() {
        let matcher = GitignoreMatcher(patterns: ["file[a-z].txt"])
        #expect(matcher.isIgnored("filea.txt"))
        #expect(matcher.isIgnored("filez.txt"))
        #expect(!matcher.isIgnored("file1.txt"))
    }

    @Test("Path-containing patterns are implicitly anchored")
    func pathContainingImplicitAnchor() {
        let matcher = GitignoreMatcher(patterns: ["src/build"])
        #expect(matcher.isIgnored("src/build"))
        #expect(!matcher.isIgnored("other/src/build"))
    }

    @Test("Trailing whitespace is stripped")
    func trailingWhitespaceStripped() {
        let matcher = GitignoreMatcher(patterns: ["*.log   "])
        #expect(matcher.isIgnored("debug.log"))
    }

    @Test("Escaped hash is not treated as comment")
    func escapedHash() {
        let matcher = GitignoreMatcher(patterns: ["\\#file"])
        #expect(matcher.isIgnored("#file"))
    }

    @Test("Case sensitivity is respected")
    func caseSensitivity() {
        let matcher = GitignoreMatcher(patterns: ["Makefile"])
        #expect(matcher.isIgnored("Makefile"))
        #expect(!matcher.isIgnored("makefile"))
        #expect(!matcher.isIgnored("MAKEFILE"))
    }
}
