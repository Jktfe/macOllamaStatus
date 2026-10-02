// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "olusage",
    platforms: [.macOS(.v14)],
    targets: [
        // Pure parsing logic, no UI, so it is easy to test.
        .target(name: "OlusageCore"),
        .executableTarget(name: "olusage", dependencies: ["OlusageCore"]),
        .testTarget(name: "OlusageCoreTests", dependencies: ["OlusageCore"]),
    ]
)
