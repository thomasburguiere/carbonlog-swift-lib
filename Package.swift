// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CarbonLogLib",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CarbonLogLib",
            targets: ["CarbonLogLib"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.4"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CarbonLogLib",
            dependencies: []
        ),
        .testTarget(
            name: "CarbonLogLibTests",
            dependencies: ["CarbonLogLib"],
            resources: [
                .copy("Resources"),
                .copy("Resources/test-input.csv"),
                .copy("Resources/test-empty.csv"),
                .copy("Resources/test-garbage.csv"),
                .copy("Resources/test-mixed-input.csv"),
            ]
        ),
    ]
)
