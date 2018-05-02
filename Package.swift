// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "foundationdb",
    products: [
        .library(
            name: "foundationdb",
            targets: ["foundationdb"]),
    ],
    dependencies: [
         .package(url: "https://github.com/nunomaia/CFoundationdb", from: "0.0.2")  ,
    ],
    targets: [
        .target(
            name: "foundationdb",
            dependencies: ["CFoundationdb"]),
        .testTarget(
            name: "foundationdbTests",
            dependencies: ["foundationdb"]),
    ]
)
