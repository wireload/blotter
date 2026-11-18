// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BlotterKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "BlotterKit", targets: ["BlotterKit"])
    ],
    targets: [
        .target(name: "BlotterKit"),
        .testTarget(name: "BlotterKitTests", dependencies: ["BlotterKit"]),
    ]
)
