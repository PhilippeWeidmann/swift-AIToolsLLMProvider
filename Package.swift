// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AIToolsLLMProvider",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AIToolsLLMProvider",
            targets: ["AIToolsLLMProvider"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AIToolsLLMProvider",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "AIToolsLLMProviderTests",
            dependencies: ["AIToolsLLMProvider"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ],
    swiftLanguageModes: [.v6]
)
