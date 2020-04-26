// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "corvus",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "Corvus", targets: ["Corvus"])
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(
            url: "https://github.com/vapor/vapor.git",
            from: "4.0.0"
        ),

        // 💧 Vapor's ORM Framework.
        .package(
            url: "https://github.com/vapor/fluent.git",
            from: "4.0.0-rc.3"
        ),
        
        // A JWT driver.
        .package(
            url: "https://github.com/vapor/jwt.git",
            from: "4.0.0-rc"
        ),

        // A database driver for testing.
        .package(
            url: "https://github.com/vapor/fluent-sqlite-driver.git",
            from: "4.0.0-rc.2"
        )
    ],
    targets: [
        // Corvus
        .target(
            name: "Corvus",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "JWT", package: "jwt")
            ]
        ),

        // Testing
        .testTarget(name: "CorvusTests", dependencies: [
            .target(name: "Corvus"),
            .product(name: "XCTVapor", package: "vapor"),
            .product(
                name: "FluentSQLiteDriver",
                package: "fluent-sqlite-driver"
            )
        ])
    ]
)
