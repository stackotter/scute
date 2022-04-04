// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "WebsiteBuilder",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.8.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.1.1"),
        .package(url: "https://github.com/stackotter/swift-cmark-gfm", from: "1.0.2"),
        .package(url: "https://github.com/stackotter/Parsley", branch: "custom-extensions"),
        .package(url: "https://github.com/scinfu/SwiftSoup", from: "2.3.8"),
        .package(url: "https://github.com/swhitty/FlyingFox", from: "0.6.0"),
    ],
    targets: [
        .target(
            name: "Scute",
            dependencies: [
                .product(name: "Parsing", package: "swift-parsing"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "CMarkGFM", package: "swift-cmark-gfm"),
                "Parsley",
                "SwiftSoup",
                "FlyingFox",
                "CMarkExtension"
            ]
        ),
        .executableTarget(
            name: "ScuteCLI",
            dependencies: [
                "Scute"
            ]
        ),
        .target(
            name: "CMarkExtension",
            dependencies: [
                .product(name: "CMarkGFM", package: "swift-cmark-gfm")
            ],
            publicHeadersPath: "."
        ),
        .testTarget(
            name: "ScuteTests",
            dependencies: ["Scute"]
        ),
    ]
)
