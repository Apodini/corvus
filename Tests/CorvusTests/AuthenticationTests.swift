import Corvus
import Fluent
import FluentSQLiteDriver
import Vapor
import XCTVapor
import Foundation

// swiftlint:disable file_length type_body_length function_body_length
final class AuthenticationTests: XCTestCase {

    func testBasicAuthenticatorSuccess() throws {
        final class BasicAuthenticatorTest: RestApi {

            var content: Endpoint {
                Group("api") {
                    User<CorvusUser>("users", softDelete: false)

                    BasicAuthGroup<CorvusUser>("accounts") {
                        Create<Account>()
                    }
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let basicAuthenticatorTest = BasicAuthenticatorTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.middleware.use(CorvusUser.authenticator())
        app.migrations.add(CreateAccount())
        app.migrations.add(CreateCorvusUser())

        try app.autoMigrate().wait()
        
        try app.register(collection: basicAuthenticatorTest)
        let basic = "berzan:pass"
            .data(using: .utf8)!
            .base64EncodedString()
        
        let user = CorvusUser(
            username: "berzan",
            passwordHash: try Bcrypt.hash("pass")
        )

        let account = Account(name: "Berzan")
        
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
                headers: [
                    "Authorization": "Basic \(basic)",
                    "content-type": "application/json"
                ],
                body: account.encode()
            ) { res in
                print(res.body.string)
                XCTAssertEqual(res.status, .ok)
            }
    }

    func testBasicAuthenticatorFailure() throws {
        final class BasicAuthenticatorTest: RestApi {

            var content: Endpoint {
                Group("api") {
                    User<CorvusUser>("users", softDelete: false)

                    BasicAuthGroup<CorvusUser>("accounts") {
                        Create<Account>()
                    }
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let basicAuthenticatorTest = BasicAuthenticatorTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.middleware.use(CorvusUser.authenticator())
        app.migrations.add(CreateAccount())
        app.migrations.add(CreateCorvusUser())

        try app.autoMigrate().wait()

        try app.register(collection: basicAuthenticatorTest)
        
        let user = CorvusUser(
            username: "berzan",
            passwordHash: try Bcrypt.hash("pass")
        )
        let account = Account(name: "berzan")
        
        let basic = "berzan:wrong"
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
                    User<CorvusUser>("users", softDelete: false)

                    Login<CorvusToken>("login")

                    BearerAuthGroup<CorvusToken>("accounts") {
                        Create<Account>()
                    }
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let bearerAuthenticatorTest = BearerAuthenticatorTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.middleware.use(CorvusToken.authenticator())
        app.middleware.use(CorvusUser.authenticator())
        app.migrations.add(CreateAccount())
        app.migrations.add(CreateCorvusUser())
        app.migrations.add(CreateCorvusToken())

        try app.autoMigrate().wait()

        try app.register(collection: bearerAuthenticatorTest)
        
        let user = CorvusUser(
            username: "berzan",
            passwordHash: try Bcrypt.hash("pass")
        )
        let account = Account(name: "berzan")
        
        let basic = "berzan:pass"
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
                headers: [
                    "content-type": "application/json",
                    "Authorization": "Bearer \(token.value)"
                ],
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
                    User<CorvusUser>("users", softDelete: false)

                    Login<CorvusToken>("login")

                    BearerAuthGroup<CorvusToken>("accounts") {
                        Create<Account>()
                    }
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let bearerAuthenticatorTest = BearerAuthenticatorTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.middleware.use(CorvusToken.authenticator())
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
                    CRUD<CorvusUser>("users", softDelete: false)

                    Login<CorvusToken>("login")

                    BearerAuthGroup<CorvusToken>("accounts") {
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
        app.middleware.use(CorvusToken.authenticator())
        app.middleware.use(CorvusUser.authenticator())
        app.migrations.add(CreateSecureAccount())
        app.migrations.add(CreateCorvusUser())
        app.migrations.add(CreateCorvusToken())

        try app.autoMigrate().wait()

        try app.register(collection: authModifierTest)

        let user1 = CorvusUser(
             username: "berzan",
             passwordHash: try Bcrypt.hash("pass")
         )

        let user2 = CorvusUser(
             username: "paul",
             passwordHash: try Bcrypt.hash("pass")
         )

        var account: SecureAccount!

        let basic1 = "berzan:pass"
               .data(using: .utf8)!
               .base64EncodedString()

        let basic2 = "paul:pass"
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

    func testAuthModifierCustom() throws {
        final class AuthModifierTest: RestApi {

            let testParameter = Parameter<CustomAccount>()

            var content: Endpoint {
                Group("api") {
                    CRUD<CustomUser>("users", softDelete: false)

                    Login<CustomToken>("login")

                    BearerAuthGroup<CustomToken>("accounts") {
                        Create<CustomAccount>()
                        Group(testParameter.id) {
                            ReadOne<CustomAccount>(testParameter.id)
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
        app.middleware.use(CustomToken.authenticator())
        app.middleware.use(CustomUser.authenticator())
        app.migrations.add(CreateCustomAccount())
        app.migrations.add(CreateCustomUser())
        app.migrations.add(CreateCustomToken())

        try app.autoMigrate().wait()

        try app.register(collection: authModifierTest)

        let user1 = CustomUser(
             username: "berzan",
             surname: "yildiz",
             email: "berzan@corvus.com",
             passwordHash: try Bcrypt.hash("pass")
         )

        let user2 = CustomUser(
             username: "paul",
             surname: "schmiedmayer",
             email: "paul@corvus.com",
             passwordHash: try Bcrypt.hash("pass")
         )

        var account: CustomAccount!

        let basic1 = "berzan:pass"
               .data(using: .utf8)!
               .base64EncodedString()

        let basic2 = "paul:pass"
                .data(using: .utf8)!
                .base64EncodedString()

        var token1: CustomToken!
        var token2: CustomToken!
        var accountRes: CustomAccount!
        
        try app.testable()
            .test(
                .POST,
                "/api/users",
                headers: ["content-type": "application/json"],
                body: user1.encode(),
                afterResponse: { res in
                    let userRes = try res.content.decode(CustomUser.self)
                    account = CustomAccount(
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
                token1 = try res.content.decode(CustomToken.self)
                XCTAssertTrue(true)
              }
            .test(
                .POST,
                "/api/login",
                headers: ["Authorization": "Basic \(basic2)"]
            ) { res in
                token2 = try res.content.decode(CustomToken.self)
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
                  accountRes = try res.content.decode(CustomAccount.self)
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
    
    func testUserAuthModifier() throws {
        final class UserAuthModifierTest: RestApi {

            var content: Endpoint {
                Group("api") {
                    Create<CorvusUser>()
                    User<CorvusUser>("users")
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let userAuthModifierTest = UserAuthModifierTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.middleware.use(CorvusUser.authenticator())
        app.migrations.add(CreateCorvusUser())

        try app.autoMigrate().wait()

        try app.register(collection: userAuthModifierTest)

        let user1 = CorvusUser(
             username: "berzan",
             passwordHash: try Bcrypt.hash("pass")
         )

        let user2 = CorvusUser(
             username: "paul",
             passwordHash: try Bcrypt.hash("pass")
         )

        let basic1 = "berzan:pass"
               .data(using: .utf8)!
               .base64EncodedString()

        let basic2 = "paul:pass"
                .data(using: .utf8)!
                .base64EncodedString()
        
        var userRes: CorvusUser!
        
        try app.testable()
            .test(
                .POST,
                "/api",
                headers: ["content-type": "application/json"],
                body: user1.encode(),
                afterResponse: { res in
                    userRes = try res.content.decode(CorvusUser.self)
                }
            )
            .test(
                .POST,
                "/api/users",
                headers: ["content-type": "application/json"],
                body: user2.encode()
             )
            .test(
                  .GET,
                  "/api/users/\(userRes.id!)",
                  headers: [
                      "Authorization": "Basic \(basic2)"
                  ]
                ) { res in
                    XCTAssertEqual(res.status, .unauthorized)
                }
            .test(
                  .GET,
                  "/api/users/\(userRes.id!)",
                  headers: [
                      "Authorization": "Basic \(basic1)"
                  ]
                ) { res in
                    XCTAssertEqual(res.status, .ok)
                    XCTAssertEqualJSON(res.body.string, user1)
                }
    }
    
    func testCreateAuthModifier() throws {
           final class CreateAuthModifierTest: RestApi {

               var content: Endpoint {
                   Group("api") {
                       Group("accounts") {
                           Create<SecureAccount>().auth(\.$user)
                       }
                    
                       Create<CorvusUser>()
                       User<CorvusUser>("users", softDelete: false)
                   }
               }
           }

           let app = Application(.testing)
           defer { app.shutdown() }
           let createAuthModifierTest = CreateAuthModifierTest()

           app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
           app.middleware.use(CorvusUser.authenticator())
           app.migrations.add(CreateSecureAccount())
           app.migrations.add(CreateCorvusUser())

           try app.autoMigrate().wait()

           try app.register(collection: createAuthModifierTest)

           let user1 = CorvusUser(
                username: "berzan",
                passwordHash: try Bcrypt.hash("pass")
            )

           let user2 = CorvusUser(
                username: "paul",
                passwordHash: try Bcrypt.hash("pass")
            )

           let basic1 = "berzan:pass"
                  .data(using: .utf8)!
                  .base64EncodedString()

           let basic2 = "paul:pass"
                   .data(using: .utf8)!
                   .base64EncodedString()
           
           var account: SecureAccount!
           
           try app.testable()
               .test(
                     .POST,
                     "/api",
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
                   "/api/accounts",
                   headers: [
                       "content-type": "application/json",
                       "Authorization": "Basic \(basic2)"
                   ],
                   body: account.encode()
                ) { res in
                    XCTAssertEqual(res.status, .unauthorized)
                }
                .test(
                      .POST,
                      "/api/accounts",
                      headers: [
                          "content-type": "application/json",
                          "Authorization": "Basic \(basic1)"
                      ],
                      body: account.encode()
                   ) { res in
                       XCTAssertEqual(res.status, .ok)
               }
       }
    
    func testSecureCRUD() throws {
        final class SecureCRUDTest: RestApi {

            var content: Endpoint {
                Group("api") {
                    Create<CorvusUser>()
                    User<CorvusUser>("users")
                    CRUD<SecureAccount>("accounts").auth(\.$user)
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let secureCRUDTest = SecureCRUDTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.middleware.use(CorvusUser.authenticator())
        app.migrations.add(CreateCorvusUser())
        app.migrations.add(CreateSecureAccount())


        try app.autoMigrate().wait()

        try app.register(collection: secureCRUDTest)

        let user1 = CorvusUser(
             username: "berzan",
             passwordHash: try Bcrypt.hash("pass")
         )

        let user2 = CorvusUser(
             username: "paul",
             passwordHash: try Bcrypt.hash("pass")
         )

        let basic1 = "berzan:pass"
               .data(using: .utf8)!
               .base64EncodedString()

        let basic2 = "paul:pass"
                .data(using: .utf8)!
                .base64EncodedString()
        
        var account: SecureAccount!

        try app.testable()
            .test(
                 .POST,
                 "/api",
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
                  "/api/accounts",
                  headers: [
                      "content-type": "application/json",
                      "Authorization": "Basic \(basic2)"
                  ],
                  body: account.encode()
               ) { res in
                   XCTAssertEqual(res.status, .unauthorized)
            }
            .test(
                 .POST,
                 "/api/accounts",
                 headers: [
                     "content-type": "application/json",
                     "Authorization": "Basic \(basic1)"
                 ],
                 body: account.encode()
              ) { res in
                  XCTAssertEqual(res.status, .ok)
            }
    }
    
    func testNestedAuthModifier() throws {
        final class NestedAuthModifierTest: RestApi {

            let testParameter = Parameter<SecureTransaction>()

            var content: Endpoint {
                Group("api") {
                    CRUD<CorvusUser>("users", softDelete: false)

                    Group("accounts") {
                        Create<SecureAccount>()
                    }
                    
                    BasicAuthGroup<CorvusUser>("transactions") {
                        Create<SecureTransaction>()
                        
                        Group(testParameter.id) {
                            ReadOne<SecureTransaction>(testParameter.id)
                                .auth(\.$account, \.$user)
                        }
                    }
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let nestedAuthModifierTest = NestedAuthModifierTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.middleware.use(CorvusUser.authenticator())
        app.migrations.add(CreateSecureAccount())
        app.migrations.add(CreateSecureTransaction())
        app.migrations.add(CreateCorvusUser())

        try app.autoMigrate().wait()

        try app.register(collection: nestedAuthModifierTest)

        let user1 = CorvusUser(
             username: "berzan",
             passwordHash: try Bcrypt.hash("pass")
         )

        let user2 = CorvusUser(
             username: "paul",
             passwordHash: try Bcrypt.hash("pass")
         )

        var account: SecureAccount!
        var transaction: SecureTransaction!

        let basic1 = "berzan:pass"
               .data(using: .utf8)!
               .base64EncodedString()

        let basic2 = "paul:pass"
                .data(using: .utf8)!
                .base64EncodedString()

        var transactionRes: SecureTransaction!
        
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
                "/api/accounts",
                headers: ["content-type": "application/json"],
                body: account.encode()
              ) { res in
                  let accountRes = try res.content.decode(SecureAccount.self)
                  transaction = SecureTransaction(
                    amount: 42.0,
                     currency: "€",
                     accountID: accountRes.id!
                  )
            }
            .test(
                .POST,
                "/api/transactions",
                headers: [
                    "content-type": "application/json",
                    "Authorization": "Basic \(basic1)"
                ],
                body: transaction.encode()
              ) { res in
                  transactionRes = try res.content.decode(
                    SecureTransaction.self
                  )
                  XCTAssertTrue(true)
              }
            .test(
                  .GET,
                  "/api/transactions/\(transactionRes.id!)",
                  headers: [
                      "Authorization": "Basic \(basic2)"
                  ]
                ) { res in
                    XCTAssertEqual(res.status, .unauthorized)
                }
            .test(
                  .GET,
                  "/api/transactions/\(transactionRes.id!)",
                  headers: [
                      "Authorization": "Basic \(basic1)"
                  ]
                ) { res in
                    XCTAssertEqual(res.status, .ok)
                    print(res.body.string)
                    XCTAssertEqualJSON(res.body.string, transaction)
                }
    }
}
