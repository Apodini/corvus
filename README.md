# Corvus

<p align="center">
  <img width="200" src="https://raw.githubusercontent.com/Apodini/corvus/master/images/crow.png">
</p>

<p align="center">
	<a href="https://apodini.github.io/corvus-docs/">
        <img src="http://img.shields.io/badge/read_the-docs-2196f3.svg" alt="Documentation">
    </a>
    <a href="LICENSE">
        <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://github.com/Apodini/corvus/actions">
        <img src="https://github.com/Apodini/corvus/workflows/test/badge.svg?branch=master" alt="Continuous Integration">
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
import Corvus

final class Api: RestApi {

    let accountParameter = Parameter<Account>()

    var content: Endpoint {
        Group {
            BearerAuthGroup("api") {
                Group("accounts") {
                    Create<Account>()
                    ReadAll<Account>().auth(\.$user)
                    
                    Group(accountParameter.id) {
                        ReadOne<Account>(accountParameter.id)
                            .auth(\.$user)
                        Update<Account>(accountParameter.id)
                            .auth(\.$user)
                        Delete<Account>(accountParameter.id)
                            .auth(\.$user)

                        Group("transactions") {
                            ReadOne<Account>(accountParameter.id)
                                .children(\.$transactions).auth(\.$user)
                        }
                    }
                }

                CRUD<Transaction>("transactions")
            }

            Login("login")

            CRUD<CorvusUser>("users", softDelete: false)
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
    name: "app",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .executable(name: "Run", targets: ["Run"]),
        .library(name: "App", targets: ["App"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(
            url: "https://github.com/Apodini/corvus",
            from: "0.0.8"
        ),

        .package(
            url: "https://github.com/vapor/fluent-sqlite-driver.git",
            from: "4.0.0-rc"
        ),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Corvus", package: "corvus"),
                .product(
                    name: "FluentSQLiteDriver",
                    package: "fluent-sqlite-driver"
                ),
            ]
        ),
        .target(name: "Run", dependencies: ["App"]),
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

func configure(_ app: Application) throws {

  try app.autoMigrate().wait()

  try routes(app)
}
```

And `routes.swift`, which registers the routes from the `Corvus` API:
```Swift
import Corvus
import Vapor

func routes(_ app: Application) throws {
    let api = Api()
    try app.register(collection: api)
}
```

The collection `Api` is a struct conforming to `Corvus`'s `RestApi` protocol. It may look
something like this:

```Swift
final class Api: RestApi {

    var content: Endpoint {
        Group("api", "accounts") {
            Create<Account>()
            ReadAll<Account>()
        }
    }
}
```

Finally the application's `main.swift` function (which is usually under the path `Sources/Run`) should look like this:

```Swift
import App
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
try configure(app)
try app.run()
```

# How to use

In general, there are two types of building blocks for a `Corvus` API: Group components, which
allow users to group more groups or concrete endpoints under a common route path, or 
components that provide concrete functionality, like `Create` or `ReadAll`. Check out the 
[docs](https://apodini.github.io/corvus-docs/) and the [example project](https://github.com/Apodini/corvus-example-project) to learn more!

# How to contribute

Just create an issue with your proposal, and if that is accepted, a pull request with your change
should suffice.

# Sources
The logo: Made by [Freepik](https://www.flaticon.com/authors/freepik)

[Vapor](https://github.com/vapor/vapor)

[Fluent](https://github.com/vapor/fluent)
