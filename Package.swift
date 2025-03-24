// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NnGitKit",
    products: [
        .library(name: "GitShellKit", targets: ["GitShellKit"]),
        .library(name: "GitCommandGen", targets: ["GitCommandGen"]),
    ],
    targets: [
        .target(name: "GitCommandGen"),
        .target(name: "GitShellKit", dependencies: ["GitCommandGen"]),
        .testTarget(name: "NnGitKitTests", dependencies: ["GitShellKit"])
    ]
)
