// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "LINGYAOSnapshot",
    platforms: [.macOS(.v13)],
    products: [.library(name: "LINGYAOSnapshot", targets: ["LINGYAOSnapshot"])],
    targets: [
        .target(name: "LINGYAOSnapshot", linkerSettings: [.linkedLibrary("sqlite3")]),
        .testTarget(name: "LINGYAOSnapshotTests", dependencies: ["LINGYAOSnapshot"])
    ]
)
