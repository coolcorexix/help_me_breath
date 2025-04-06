// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "help_me_breath",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "help_me_breath",
            targets: ["help_me_breath"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.1")
    ],
    targets: [
        .executableTarget(
            name: "help_me_breath",
            dependencies: ["HotKey"],
            path: "Sources/help_me_breath",
            resources: [
                .copy("Resources/Assets.xcassets")
            ]
        )
    ]
)
