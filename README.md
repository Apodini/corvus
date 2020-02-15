# Corvus

<p align="center">
  <img width="200" src="images/crow.png">
</p>

Corvus is the first truly declarative server-side framework for Swift. It provides a declarative, composable syntax which makes it easy to get APIs up and running. It is based heavily on the existing work from [Vapor](https://github.com/vapor/vapor).

# How to set up

After your Swift Project, in the `Package.Swift` file, you will need to add the dependencies 
for `Corvus` and a `Fluent` database driver of your choice. Below is an example with an 
`SQLite` driver:

```Swift
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
      // A server-side Swift web framework.
      .package(
          url: "https://github.com/bmikaili/corvus.git",
          from: "0.0.4"
      ),

      .package(
          url: "https://github.com/vapor/fluent-sqlite-driver.git",
          from: "4.0.0-beta.3"
      ),
  ],
  targets: [
      .target(
          name: "App",
          dependencies: [
              "Corvus",
              "FluentSQLiteDriver",
          ]
      ),
      .target(name: "Run", dependencies: ["App"]),
  ]
)
```

Additionally, under the application's `Source` folder (by default that is `Sources/App`), three 
setup functions need to be present:

`app.swift`, which looks like this:

```Swift
import Corvus
import Vapor

public func app(_ environment: Environment) throws -> Application {
  var environment = environment
  try LoggingSystem.bootstrap(from: &environment)
  let app = Application(environment)
  try configure(app)
  return app
}
```

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

And finally `routes.swift`, which registers the routes from the `Corvus` API:
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
