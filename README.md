# Corvus

<p align="center">
  <img width="200" src="https://raw.githubusercontent.com/Apodini/corvus/release/images/crow.png">
</p>

<p align="center">
	<a href="https://apodini.github.io/corvus/">
        <img src="http://img.shields.io/badge/read_the-docs-2196f3.svg" alt="Documentation">
    </a>
    <a href="LICENSE">
        <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://github.com/Apodini/corvus/actions">
        <img src="https://github.com/Apodini/corvus/workflows/test/badge.svg?branch=release" alt="Continuous Integration">
    </a>
    <a href="https://swift.org">
        <img src="https://img.shields.io/badge/swift-5.2-brightgreen.svg" alt="Swift 5.2">
    </a>
</p>

<br>

Corvus is the first truly declarative server-side framework for Swift. It provides a declarative, composable syntax which makes it easy to get APIs up and running. It is based heavily on the existing work from [Vapor](https://github.com/vapor/vapor).

# Example

Below is an example of a full-featured API that manages Bank Accounts and Transactions belonging to certain users. It also showcases the ease of using authentication and setting authorization rules for specific routes.

```Swift
let xpenseApi = Api("api") {
    User<CorvusUser>("users")
    
    Login<CorvusToken>("login")
    
    BearerAuthGroup<CorvusToken> {
        AccountsEndpoint()
        TransactionsEndpoint()
    }
}
```

Because Corvus is composable, it is easy to use a group of components as its own component:
```Swift
final class AccountsEndpoint: Endpoint {
    let parameter = Parameter<Account>()
    
    var content: Endpoint {
        Group("accounts") {
            Create<Account>().auth(\.$user)
            ReadAll<Account>().auth(\.$user)
            
            Group(parameter.id) {
                ReadOne<Account>(parameter.id).auth(\.$user)
                Update<Account>(parameter.id).auth(\.$user)
                Delete<Account>(parameter.id).auth(\.$user)
            }
        }
    }
}
```

# How to set up

After your Swift Project, in the `Package.Swift` file, you will need to add the dependencies 
for `Corvus` and a `Fluent` database driver of your choice. Below is an example with an 
`SQLite` driver:

```Swift
// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "XpenseServer",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "XpenseServer", targets: ["XpenseServer"])
    ],
    dependencies: [
        .package(url: "https://github.com/Apodini/corvus.git", from: "0.0.14"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0-rc")
    ],
    targets: [
        .target(name: "Run",
                dependencies: [
                    .target(name: "XpenseServer")
                ]),
        .target(name: "XpenseServer",
                dependencies: [
                    .product(name: "Corvus", package: "corvus"),
                    .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
                ]),
        .testTarget(name: "XpenseServerTests",
                    dependencies: [
                        .target(name: "XpenseServer"),
                        .product(name: "XCTVapor", package: "vapor"),
                        .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
                    ])
    ]
)
```

Additionally, under the application's `Source` folder (by default that is `Sources/App`), two setup functions need to be present:

`configure.swift`, in which you can configure middlewares, databases and migrations used
in the application:

```Swift
import Corvus
import Vapor
import FluentSQLiteDriver

public func configure(_ app: Application) throws {
    app.middleware.use(CorvusUser.authenticator())
    app.middleware.use(CorvusToken.authenticator())
    
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    app.migrations.add(CreateAccount())
    app.migrations.add(CreateTransaction())
    app.migrations.add(CreateCorvusUser())
    app.migrations.add(CreateCorvusToken())

    try app.autoMigrate().wait()
}
```

And `routes.swift`, which registers the routes from the `Corvus` API:
```Swift
import Corvus
import Vapor

public func routes(_ app: Application) throws {
    try app.register(collection: xpenseApi)
}
```

Finally the application's `main.swift` file (which is usually under the path `Sources/Run`) should look like this:

```Swift
import App
import Vapor

var environment = try Environment.detect()
try LoggingSystem.bootstrap(from: &environment)
let app = Application(environment)
try configure(app)
try routes(app)
defer {
    app.shutdown()
}
try app.run()
```

# How to use

In general, there are two types of building blocks for a `Corvus` API: Group components, which
allow users to group more groups or concrete endpoints under a common route path, or 
components that provide concrete functionality, like `Create` or `ReadAll`. Check out the 
[docs](https://apodini.github.io/corvus/) and the [example project](https://github.com/Apodini/corvus-example-project) to learn more!

# How to contribute

Review our [contribution guidelines](https://github.com/Apodini/.github/blob/release/CONTRIBUTING.md) for contribution formalities.

# Sources
The logo: Made by [Freepik](https://www.flaticon.com/authors/freepik)

[Vapor](https://github.com/vapor/vapor)

[Fluent](https://github.com/vapor/fluent)
