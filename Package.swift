// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WalkieClaude",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "WalkieClaude",
            path: "Sources/WalkieClaude",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
