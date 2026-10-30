// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NetworkMenuBarKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "NetworkMenuBarKit", targets: ["NetworkMenuBarKit"]),
        .executable(name: "nmb-dump", targets: ["nmb-dump"]),
    ],
    targets: [
        .target(name: "NetworkMenuBarKit"),
        .executableTarget(name: "nmb-dump", dependencies: ["NetworkMenuBarKit"]),
        .testTarget(name: "NetworkMenuBarKitTests", dependencies: ["NetworkMenuBarKit"]),
    ]
)
