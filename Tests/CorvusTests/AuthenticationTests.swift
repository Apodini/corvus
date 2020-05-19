import Corvus
import Fluent
import FluentSQLiteDriver
import Vapor
import XCTVapor
import Foundation

final class AuthenticationTests: CorvusTests {
    
    var account = Account(name: "James' Bond")

    override func setUpWithError() throws {
        try super.setUpWithError()

        let api = Api("api") {
            Login<CorvusToken>("login")

            BasicAuthGroup<CorvusUser>("accounts") {
                Create<Account>()
            }
        }

        try app.register(collection: api)
        user1.id.map { account.$user.id = $0 }
    }

    func testBasicAuthenticatorSuccess() throws {
        try tester()
            .test(
                .POST,
                "/api/accounts",
                headers: [
                    "Authorization": "\(user1.basicAuth())",
                    "content-type": "application/json"
                ],
                body: account.encode()
            ) { res in
                XCTAssertEqual(res.status, .ok)
            }
    }

    func testBasicAuthenticatorFailure() throws {
        try tester()
            .test(
                .POST,
                "/api/accounts",
                headers: ["Authorization": "Basic wrong"],
                body: account.encode()
            ) { res in
                XCTAssertEqual(res.status, .unauthorized)
            }
    }

    func testBearerAuthenticatorSuccess() throws {
        try tester()
            .test(
                .POST,
                "/api/accounts",
                headers: [
                    "content-type": "application/json",
                    "Authorization": "\(user1.bearerToken())"
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
        try tester()
            .test(
                .POST,
                "/api/accounts",
                headers: ["Authorization": "Bearer wrong"]
            ) { res in
                XCTAssertEqual(res.status, .unauthorized)
            }
    }
    
    func testLogin() throws {
        var user = TestUser(username: "admin", password: "admin123")
        let corvusUser = CorvusUser(
            username: user.username,
            password: try Bcrypt.hash(user.password)
        )

        try corvusUser.create(on: database()).wait()
        user.id = corvusUser.id
        
        try app.testable()
            .test(
                .POST,
                "/api/login",
                headers: ["Authorization": "\(user.basicAuth())"]
            ) { res in
                let token = try res.content.decode(CorvusToken.self)
                XCTAssertEqual(token.$user.id, user.id)
              }
    }
}
