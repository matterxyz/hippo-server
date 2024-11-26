// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "hippo-server",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .executable(name: "hippod", targets: ["Server"]),
        .library(name: "HippoServer", targets: ["App"]),
        .library(name: "DeviceCheck", targets: ["DeviceCheck"]),
        .library(name: "HummingbirdDeviceCheck", targets: ["HummingbirdDeviceCheck"]),
        .library(name: "Hippo", targets: ["Hippo"]),
        .library(name: "HippoAWS", targets: ["HippoAWS"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.1"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.3.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.4.0"),
        .package(url: "https://github.com/soto-project/soto.git", from: "7.1.0"),
        .package(url: "https://github.com/vapor/jwt-kit.git", exact: "5.0.0-rc.2"),
        .package(url: "https://github.com/apple/swift-http-types.git", from: "1.3.0"),
        // .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.4"),
    ],
    targets: [
        .executableTarget(
            name: "Server",
            dependencies: [
                .byName(name: "App"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Hummingbird", package: "hummingbird")
            ]
        ),
        .target(
            name: "Hippo",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .testTarget(
            name: "HippoTests",
            dependencies: ["Hippo"]
        ),
        .target(
            name: "App",
            dependencies: [
                .byName(name: "HippoAPIv1"),
                .byName(name: "Hippo"),
                .byName(name: "HippoAWS"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "Logging", package: "swift-log")
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
            ]
        ),
        .target(
            name: "HippoAWS",
            dependencies: [
                .product(name: "SotoS3", package: "soto"),
                .product(name: "SotoDynamoDB", package: "soto"),
                .byName(name: "Hippo")
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .byName(name: "App"),
				.product(name: "HummingbirdTesting", package: "hummingbird"),
            ]
        ),
        .target(name: "HippoAPIv1", dependencies: [
            .byName(name: "HippoAWS"),
            .byName(name: "HummingbirdDeviceCheck"),
            .product(name: "Hummingbird", package: "Hummingbird"),
            .product(name: "Logging", package: "swift-log")
        ]),
        .testTarget(
            name: "HippoAPIv1Tests",
            dependencies: [
                .byName(name: "HippoAPIv1"),
				.product(name: "HummingbirdTesting", package: "hummingbird"),
            ]
        ),
        .target(
            name: "DeviceCheck",
            dependencies: [
                .product(name: "JWTKit", package: "jwt-kit"),
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        /// Used to insert DeviceCheck as middleware for hummingbird requests
        .target(
            name: "HummingbirdDeviceCheck",
            dependencies: [
                .byName(name: "DeviceCheck"),
                .product(name: "Hummingbird", package: "hummingbird")
            ]
        ),
        .testTarget(
            name: "HBDeviceCheckTests",
            dependencies: [
                .byName(name: "HummingbirdDeviceCheck"),
				.product(name: "HummingbirdTesting", package: "hummingbird"),
            ]
        ),
        .testTarget(
            name: "HippoAWSTests",
            dependencies: [
                .byName(name: "HippoAWS"),
            ]
        ),
    ]
)
