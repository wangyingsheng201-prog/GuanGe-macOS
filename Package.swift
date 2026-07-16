// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GuanGe",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "GuanGe", targets: ["GuanGe"])
    ],
    targets: [
        .executableTarget(
            name: "GuanGe",
            path: "Sources/GuanGe"
        )
    ]
)
