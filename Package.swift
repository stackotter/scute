// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "scute",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "scute", targets: ["scute"]),
        .library(name: "ScuteCore", targets: ["ScuteCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.8.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.1.1"),
        .package(url: "https://github.com/stackotter/swift-cmark-gfm", from: "1.0.2"),
        .package(url: "https://github.com/stackotter/swift-css-parser", from: "0.1.0"),
        .package(url: "https://github.com/loopwerk/Parsley", from: "0.9.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup", from: "2.3.8"),
        .package(url: "https://github.com/swhitty/FlyingFox", from: "0.6.0"),
        .package(url: "https://github.com/LebJe/TOMLKit", from: "0.5.5"),
    ],
    targets: [
        .target(
            name: "ScuteCore",
            dependencies: [
                .product(name: "Parsing", package: "swift-parsing"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "CMarkGFM", package: "swift-cmark-gfm"),
                .product(name: "SwiftCSSParser", package: "swift-css-parser"),
                "Parsley",
                "SwiftSoup",
                "FlyingFox",
                "CMarkExtension",
                "TOMLKit",
            ]
        ),
        .executableTarget(
            name: "scute",
            dependencies: [
                "ScuteCore"
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
            name: "ScuteCoreTests",
            dependencies: [
                "ScuteCore"
            ]
        ),
    ]
)
