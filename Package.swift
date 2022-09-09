// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "SwiftResponsiveLabel",
    products: [
        .library(
            name: "SwiftResponsiveLabel",
            targets: ["SwiftResponsiveLabel"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftResponsiveLabel",
            dependencies: [],
	    path: "SwiftResponsiveLabel/Source"),
        .testTarget(
            name: "SwiftResponsiveLabelTests",
            dependencies: ["SwiftResponsiveLabel"]),
    ]
)
