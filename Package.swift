// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "corvus",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "Corvus", targets: ["Corvus"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(
            url: "https://github.com/vapor/vapor.git",
            from: "4.0.0-beta.3.7"
        ),

        // 💧 Vapor's ORM Framework.
        .package(
            url: "https://github.com/vapor/fluent.git",
            from: "4.0.0-beta.2.3"
        ),

        // A database driver for testing.
        .package(
            url: "https://github.com/vapor/fluent-sqlite-driver.git",
            from: "4.0.0-beta.3"
        ),
    ],
    targets: [
        // Corvus
        .target(
            name: "Corvus",
            dependencies: [
                "Fluent",
                "Vapor",
            ]
        ),

        // Testing
        .testTarget(name: "CorvusTests", dependencies: [
            "Corvus",
            "XCTVapor",
            "FluentSQLiteDriver"
        ])
    ]
)
