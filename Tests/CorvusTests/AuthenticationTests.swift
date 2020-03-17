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
        app.migrations.add(CreateAccount())
        app.migrations.add(CreateCorvusUser())

        try app.autoMigrate().wait()
        
        try app.register(collection: basicAuthenticatorTest)
        let basic = "berzan@corvus.com:pass"
            .data(using: .utf8)!
            .base64EncodedString()
        
        let user = CorvusUser(
            name: "berzan",
            email: "berzan@corvus.com",
            password: "pass"
        )

        let account = Account(name: "Berzan")
        var response: Account!
        
        try app.testable()
            .test(
                .POST,
                "/api/users",
                headers: ["content-type": "application/json"],
                body: user.encode(),
                afterResponse: {
                    response = try $0.content.decode(Account.self)
                    account.id = response.id
                }
            )
            .test(
                .POST,
                "/api/accounts",
                headers: ["Authorization": "Basic \(basic)", "content-type": "application/json"],
                body: account.encode()
            ) { res in
                print(res.body.string)
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqualJSON(
                    res.body.string,
                    account
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
        app.migrations.add(CreateAccount())
        app.migrations.add(CreateCorvusUser())

        try app.autoMigrate().wait()

        try app.register(collection: basicAuthenticatorTest)
        
        let user = CorvusUser(
            name: "berzan",
            email: "berzan@corvus.com",
            password: "pass"
        )
        let account = Account(name: "berzan")
        
        let basic = "berzan@corvus.com:wrong"
            .data(using: .utf8)!
            .base64EncodedString()

        try app.testable()
            .test(
                .POST,
                "/api/users",
                headers: ["content-type": "application/json"],
                body: user.encode()
            )
            .test(
                .POST,
                "/api/accounts",
                headers: ["Authorization": "Basic \(basic)"],
                body: account.encode()
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
        app.migrations.add(CreateAccount())
        app.migrations.add(CreateCorvusUser())
        app.migrations.add(CreateCorvusToken())

        try app.autoMigrate().wait()

        try app.register(collection: bearerAuthenticatorTest)
        
        let user = CorvusUser(
            name: "berzan",
            email: "berzan@corvus.com",
            password: "pass"
        )
        let account = Account(name: "berzan")
        
        let basic = "berzan@corvus.com:pass"
            .data(using: .utf8)!
            .base64EncodedString()

        var token: CorvusToken!

        try app.testable()
            .test(
                .POST,
                "/api/users",
                headers: ["content-type": "application/json"],
                body: user.encode()
            )
            .test(
                .POST,
                "/api/login",
                headers: ["Authorization": "Basic \(basic)"]
            ) { res in
                token = try res.content.decode(CorvusToken.self)
                XCTAssertTrue(true)
              }
            .test(
              .POST,
              "/api/accounts",
              headers: ["content-type": "application/json", "Authorization": "Bearer \(token.value)"],
              body: account.encode()
            ) { res in
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqualJSON(
                    res.body.string,
                    account
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
        app.migrations.add(CreateAccount())
        app.migrations.add(CreateCorvusUser())
        app.migrations.add(CreateCorvusToken())

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

    func testAuthModifier() throws {
        final class AuthModifierTest: RestApi {

            let testParameter = Parameter<SecureAccount>()

            var content: Endpoint {
                Group("api") {
                    CRUD<CorvusUser>("users")

                    Login("login")

                    BearerAuthGroup("accounts") {
                        Create<SecureAccount>()
                        Group(testParameter.id) {
                            ReadOne<SecureAccount>(testParameter.id)
                                .auth(\.$user)
                        }
                    }
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let authModifierTest = AuthModifierTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.middleware.use(CorvusToken.authenticator().middleware())
        app.migrations.add(CreateSecureAccount())
        app.migrations.add(CreateCorvusUser())
        app.migrations.add(CreateCorvusToken())

        try app.autoMigrate().wait()

        try app.register(collection: authModifierTest)

        let user1 = CorvusUser(
             name: "berzan",
             email: "berzan@corvus.com",
             password: "pass"
         )

        let user2 = CorvusUser(
             name: "paul",
             email: "paul@corvus.com",
             password: "pass"
         )

        var account: SecureAccount!

        let basic1 = "berzan@corvus.com:pass"
               .data(using: .utf8)!
               .base64EncodedString()

        let basic2 = "paul@corvus.com:pass"
                .data(using: .utf8)!
                .base64EncodedString()

        var token1: CorvusToken!
        var token2: CorvusToken!
        var accountRes: SecureAccount!

        try app.testable()
            .test(
                .POST,
                "/api/users",
                headers: ["content-type": "application/json"],
                body: user1.encode(),
                afterResponse: { res in
                    let userRes = try res.content.decode(CorvusUser.self)
                    account = SecureAccount(
                        name: "berzan",
                        userID: userRes.id!
                    )
                }
            )
            .test(
                .POST,
                "/api/users",
                headers: ["content-type": "application/json"],
                body: user2.encode()
             )
            .test(
                .POST,
                "/api/login",
                headers: ["Authorization": "Basic \(basic1)"]
            ) { res in
                token1 = try res.content.decode(CorvusToken.self)
                XCTAssertTrue(true)
              }
            .test(
                .POST,
                "/api/login",
                headers: ["Authorization": "Basic \(basic2)"]
            ) { res in
                token2 = try res.content.decode(CorvusToken.self)
                XCTAssertTrue(true)
              }
            .test(
                .POST,
                "/api/accounts",
                headers: [
                    "content-type": "application/json",
                    "Authorization": "Bearer \(token1.value)"
                ],
                body: account.encode()
              ) { res in
                  accountRes = try res.content.decode(SecureAccount.self)
                  XCTAssertTrue(true)
              }
            .test(
                  .GET,
                  "/api/accounts/\(accountRes.id!)",
                  headers: [
                      "Authorization": "Bearer \(token2.value)"
                  ]
                ) { res in
                    XCTAssertEqual(res.status, .unauthorized)
                }
            .test(
                  .GET,
                  "/api/accounts/\(accountRes.id!)",
                  headers: [
                      "Authorization": "Bearer \(token1.value)"
                  ]
                ) { res in
                    XCTAssertEqual(res.status, .ok)
                    XCTAssertEqualJSON(res.body.string, account)
                }
    }
}
