//
//  GitignorePattern.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 2/12/26.
//

import Foundation

/// A single compiled gitignore rule.
public struct GitignorePattern: Sendable, Equatable {
    let regex: String
    let isNegation: Bool
    let isDirectoryOnly: Bool
}

/// Evaluates paths against a set of gitignore rules.
public struct GitignoreMatcher: Sendable {
    private let patterns: [GitignorePattern]

    /// Creates a matcher from raw `.gitignore` lines.
    ///
    /// - Parameter patterns: The lines from a `.gitignore` file.
    public init(patterns: [String]) {
        self.patterns = patterns.compactMap(Self.compile)
    }

    /// Checks whether the given path is ignored, assuming it is a file.
    ///
    /// - Parameter path: A relative path to test (e.g. `"build/output.log"`).
    /// - Returns: `true` if the path matches an ignore rule.
    public func isIgnored(_ path: String) -> Bool {
        isIgnored(path, isDirectory: false)
    }

    /// Checks whether the given path is ignored.
    ///
    /// - Parameters:
    ///   - path: A relative path to test.
    ///   - isDirectory: Whether the path represents a directory.
    /// - Returns: `true` if the path matches an ignore rule.
    public func isIgnored(_ path: String, isDirectory: Bool) -> Bool {
        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        var ignored = false

        for pattern in patterns {
            if pattern.isDirectoryOnly && !isDirectory {
                continue
            }

            guard let regex = try? NSRegularExpression(pattern: pattern.regex) else {
                continue
            }

            let range = NSRange(normalizedPath.startIndex..., in: normalizedPath)
            if regex.firstMatch(in: normalizedPath, range: range) != nil {
                ignored = !pattern.isNegation
            }
        }

        return ignored
    }
}

// MARK: - Pattern Compilation
private extension GitignoreMatcher {
    static func compile(_ line: String) -> GitignorePattern? {
        // Skip blank lines
        guard !line.isEmpty else { return nil }

        // Skip comment lines (but not escaped #)
        if line.hasPrefix("#") { return nil }

        var pattern = line

        // Strip trailing unescaped whitespace
        pattern = stripTrailingWhitespace(pattern)
        guard !pattern.isEmpty else { return nil }

        // Detect and strip negation
        let isNegation: Bool
        if pattern.hasPrefix("!") {
            isNegation = true
            pattern = String(pattern.dropFirst())
        } else {
            isNegation = false
        }

        // Detect and strip directory-only trailing slash
        let isDirectoryOnly: Bool
        if pattern.hasSuffix("/") {
            isDirectoryOnly = true
            pattern = String(pattern.dropLast())
        } else {
            isDirectoryOnly = false
        }

        guard !pattern.isEmpty else { return nil }

        // Determine anchoring
        let isAnchored: Bool
        if pattern.hasPrefix("/") {
            isAnchored = true
            pattern = String(pattern.dropFirst())
        } else if pattern.contains("/") {
            // A slash in the middle means anchored
            isAnchored = true
        } else {
            isAnchored = false
        }

        // Convert glob to regex
        let regexBody = globToRegex(pattern)

        // Add prefix for unanchored patterns
        let fullRegex: String
        if !isAnchored {
            fullRegex = "^(.*/)?" + regexBody + "$"
        } else {
            fullRegex = "^" + regexBody + "$"
        }

        return GitignorePattern(regex: fullRegex, isNegation: isNegation, isDirectoryOnly: isDirectoryOnly)
    }

    static func stripTrailingWhitespace(_ string: String) -> String {
        var chars = Array(string)
        while let last = chars.last, (last == " " || last == "\t") {
            // Check if escaped
            if chars.count >= 2 && chars[chars.count - 2] == "\\" {
                break
            }
            chars.removeLast()
        }
        return String(chars)
    }

    static func globToRegex(_ glob: String) -> String {
        var result = ""
        let chars = Array(glob)
        var i = 0

        while i < chars.count {
            let c = chars[i]

            if c == "*" {
                if i + 1 < chars.count && chars[i + 1] == "*" {
                    // Double star
                    if i + 2 < chars.count && chars[i + 2] == "/" {
                        // **/ at start or middle
                        if i == 0 {
                            result += "(.*/)?";
                        } else {
                            result += "(.*/)?";
                        }
                        i += 3
                        continue
                    } else {
                        // ** at end
                        result += ".*"
                        i += 2
                        continue
                    }
                } else {
                    // Single star
                    result += "[^/]*"
                    i += 1
                    continue
                }
            } else if c == "?" {
                result += "[^/]"
                i += 1
                continue
            } else if c == "[" {
                // Character class
                var classStr = "["
                i += 1
                if i < chars.count && chars[i] == "!" {
                    classStr += "^"
                    i += 1
                }
                while i < chars.count && chars[i] != "]" {
                    classStr += String(chars[i])
                    i += 1
                }
                classStr += "]"
                i += 1 // skip closing ]
                result += classStr
                continue
            } else if c == "\\" {
                // Escaped character
                i += 1
                if i < chars.count {
                    result += NSRegularExpression.escapedPattern(for: String(chars[i]))
                    i += 1
                }
                continue
            } else {
                // Escape regex-special characters
                let special: Set<Character> = [".", "+", "^", "$", "{", "}", "(", ")", "|"]
                if special.contains(c) {
                    result += "\\" + String(c)
                } else {
                    result += String(c)
                }
                i += 1
                continue
            }
        }

        return result
    }
}
