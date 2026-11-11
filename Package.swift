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
        ),
        .library(
            name: "NnGitTesting",
            targets: ["NnGitTesting"]
        )
    ],
    targets: [
        // No dependencies on purpose: NnGitKit must not know about any shell library.
        .target(
            name: "NnGitKit"
        ),
        .target(
            name: "NnGitTesting",
            dependencies: [
                "NnGitKit"
            ]
        ),
        .testTarget(
            name: "NnGitKitTests",
            dependencies: [
                "NnGitKit",
                "NnGitTesting"
            ]
        )
    ]
)

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [.treatAllWarnings(as: .error)]
}
