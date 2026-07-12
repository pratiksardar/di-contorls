// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NotchControls",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "NotchControls", path: "Sources/NotchControls")
    ]
)
