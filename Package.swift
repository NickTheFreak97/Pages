// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "Pages",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "Pages",
            targets: ["Pages"]
        ),

    ],
    targets: [
        .target(
            name: "Pages",
            path: "Source",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        )
        
    ]
)
