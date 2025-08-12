// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWMachineLearning_Resnet50",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "WWMachineLearning_Resnet50", targets: ["WWMachineLearning_Resnet50"]),
    ],
    dependencies: [
        .package(url: "https://github.com/William-Weng/WWNetworking", from: "1.8.0")
    ],
    targets: [
        .target(name: "WWMachineLearning_Resnet50", dependencies: ["WWNetworking"], resources: [.copy("Privacy")]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
