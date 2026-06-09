// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "AIToolsLLMProvider",
    platforms: [
        .macOS(.v27), .iOS(.v27), .visionOS(.v27), .watchOS(.v27)
    ],
    products: [
        .library(
            name: "AIToolsLLMProvider",
            targets: ["AIToolsLLMProvider"]
        ),
    ],
    targets: [
        .target(
            name: "AIToolsLLMProvider"
        ),
        .testTarget(
            name: "AIToolsLLMProviderTests",
            dependencies: ["AIToolsLLMProvider"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
