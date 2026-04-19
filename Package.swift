// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "flow-random-bell-mac",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "flow-random-bell-mac"),
    ]
)
