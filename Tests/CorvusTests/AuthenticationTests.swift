import Corvus
import Fluent
import FluentSQLiteDriver
import XCTVapor

final class AuthenticationTests: XCTestCase {

    func testBasicAuthenticatorSuccess() throws {
        final class BasicAuthenticatorTest: RestApi {

            var content: Endpoint {
                Group("api") {
                    CRUD<CorvusUser>("users")

                    BasicAuthGroup("accounts") {
                        Create<Account>()
                    }
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let basicAuthenticatorTest = BasicAuthenticatorTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.middleware.use(CorvusUser.authenticator().middleware())
        app.migrations.add(Account.Migration())
        app.migrations.add(CorvusUser.Migration())

        try app.autoMigrate().wait()

        try app.register(collection: basicAuthenticatorTest)
        let basic = "berzan@corvus.com:pass"
            .data(using: .utf8)!
            .base64EncodedString()

        try app.testable()
            .test(
                .POST,
                "/api/users",
                json: [
                    "name": "berzan",
                    "email": "berzan@corvus.com",
                    "password": "pass"
                ]
            )
            .test(
                .POST,
                "/api/accounts",
                headers: ["Authorization": "Basic \(basic)"],
                json: ["name": "Berzan"]
            ) { res in
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(
                    res.body.string,
                    "{\"id\":1,\"name\":\"Berzan\"}"
                )
            }
    }

    func testBasicAuthenticatorFailure() throws {
        final class BasicAuthenticatorTest: RestApi {

            var content: Endpoint {
                Group("api") {
                    CRUD<CorvusUser>("users")

                    BasicAuthGroup("accounts") {
                        Create<Account>()
                    }
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let basicAuthenticatorTest = BasicAuthenticatorTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.middleware.use(CorvusUser.authenticator().middleware())
        app.migrations.add(Account.Migration())
        app.migrations.add(CorvusUser.Migration())

        try app.autoMigrate().wait()

        try app.register(collection: basicAuthenticatorTest)
        let basic = "berzan@corvus.com:wrong"
            .data(using: .utf8)!
            .base64EncodedString()

        try app.testable()
            .test(
                .POST,
                "/api/users",
                json: [
                    "name": "berzan",
                    "email": "berzan@corvus.com",
                    "password": "pass"
                ]
            )
            .test(
                .POST,
                "/api/accounts",
                headers: ["Authorization": "Basic \(basic)"],
                json: ["name": "Berzan"]
            ) { res in
                XCTAssertEqual(res.status, .unauthorized)
            }
    }

    func testBearerAuthenticatorSuccess() throws {
        final class BearerAuthenticatorTest: RestApi {

            var content: Endpoint {
                Group("api") {
                    CRUD<CorvusUser>("users")

                    Login("login")

                    BearerAuthGroup("accounts") {
                        Create<Account>()
                    }
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let bearerAuthenticatorTest = BearerAuthenticatorTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.middleware.use(CorvusToken.authenticator().middleware())
        app.migrations.add(Account.Migration())
        app.migrations.add(CorvusUser.Migration())
        app.migrations.add(CorvusToken.Migration())

        try app.autoMigrate().wait()

        try app.register(collection: bearerAuthenticatorTest)
        let basic = "berzan@corvus.com:pass"
            .data(using: .utf8)!
            .base64EncodedString()

        var token = CorvusToken(
            value: "test",
            userID: 1
        )

        try app.testable()
            .test(
                .POST,
                "/api/users",
                json: [
                    "name": "berzan",
                    "email": "berzan@corvus.com",
                    "password": "pass"
                ]
            )
            .test(
                .POST,
                "/api/login",
                headers: ["Authorization": "Basic \(basic)"]
            ) { res in
                token = try res.content.decode(CorvusToken.self)
                XCTAssertTrue(true)
              }.test(
                  .POST,
                  "/api/accounts",
                  headers: ["Authorization": "Bearer \(token.value)"],
                  json: ["name": "Berzan"]
              ) { res in
                  XCTAssertEqual(res.status, .ok)
                  XCTAssertEqual(
                      res.body.string,
                      "{\"id\":1,\"name\":\"Berzan\"}"
                  )
              }
    }

    func testBearerAuthenticatorFailure() throws {
        final class BearerAuthenticatorTest: RestApi {

            var content: Endpoint {
                Group("api") {
                    CRUD<CorvusUser>("users")

                    Login("login")

                    BearerAuthGroup("accounts") {
                        Create<Account>()
                    }
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let bearerAuthenticatorTest = BearerAuthenticatorTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.middleware.use(CorvusToken.authenticator().middleware())
        app.migrations.add(Account.Migration())
        app.migrations.add(CorvusUser.Migration())
        app.migrations.add(CorvusToken.Migration())

        try app.autoMigrate().wait()

        try app.register(collection: bearerAuthenticatorTest)

        try app.testable()
            .test(
                .POST,
                "/api/accounts",
                headers: ["Authorization": "Bearer wrong"]
            ) { res in
                XCTAssertEqual(res.status, .unauthorized)
            }
    }
}
