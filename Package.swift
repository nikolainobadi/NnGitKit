// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NnGitKit",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "NnGitKit",
            targets: ["NnGitKit"]
        )
    ],
    targets: [
        // No dependencies on purpose: NnGitKit must not know about any shell library.
        .target(
            name: "NnGitKit"
        ),
        .testTarget(
            name: "NnGitKitTests",
            dependencies: [
                "NnGitKit"
            ]
        )
    ]
)
