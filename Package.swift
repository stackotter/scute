// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "WebsiteBuilder",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.8.0"),
        .package(url: "https://github.com/loopwerk/Parsley", from: "0.8.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.3.8"),
    ],
    targets: [
        .executableTarget(
            name: "WebsiteBuilder",
            dependencies: [
                .product(name: "Parsing", package: "swift-parsing"),
                "Parsley",
                "SwiftSoup",
            ]
		),
        .testTarget(
            name: "WebsiteBuilderTests",
            dependencies: ["WebsiteBuilder"]
		),
    ]
)
