// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWMachineLearning_Resnet50",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "WWMachineLearning_Resnet50", targets: ["WWMachineLearning_Resnet50"]),
    ],
    targets: [
        .target(name: "WWMachineLearning_Resnet50", resources: [.copy("Privacy")]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
