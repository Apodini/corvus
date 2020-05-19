import Corvus
import Fluent
import FluentSQLiteDriver
import Vapor
import XCTVapor
import Foundation

final class AuthorizationTests: CorvusTests {

    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let accountParameter = Parameter<Account>().id
        let transactionParameter = Parameter<Transaction>().id

        let api = Api("api") {
            User<CorvusUser>("users")
            
            BearerAuthGroup<CorvusToken>("accounts") {
                Create<Account>().auth(\.$user)
                
                Group(accountParameter) {
                    ReadOne<Account>(accountParameter).auth(\.$user)
                    Update<Account>(accountParameter).auth(\.$user)
                }
            }
            
            BearerAuthGroup<CorvusToken>("transactions") {
                Create<Transaction>().auth(\.$account, \.$user)
                ReadAll<Transaction>()
                    .filter(\.$currency == "USD")
                    .auth(\.$account, \.$user)
                
                Group(transactionParameter) {
                    ReadOne<Transaction>(transactionParameter)
                        .auth(\.$account, \.$user)
                }
            }
        }

        try app.register(collection: api)
    }
    
    func testAuthModifier() throws {
        try tester()
            .test(
                .GET,
                "/api/accounts/\(accountId1)",
                headers: [
                    "Authorization": "\(user2.bearerToken())"
                ]
            ) { res in
                XCTAssertEqual(res.status, .unauthorized)
            }
            .test(
                .GET,
                "/api/accounts/\(accountId1)",
                headers: [
                    "Authorization": "\(user1.bearerToken())"
                ]
            ) { res in
                XCTAssertEqual(res.status, .ok)
            }
    }
    
    func testUserAuthModifier() throws {
        var user = TestUser(username: "admin", password: "admin123")
        let corvusUser = CorvusUser(
            username: user.username,
            password: try Bcrypt.hash(user.password)
        )

        try corvusUser.create(on: database()).wait()
        user.id = corvusUser.id
        let userId = try XCTUnwrap(user.id)

        try tester()
            .test(
                .POST,
                "/api/users",
                headers: ["content-type": "application/json"],
                body: user2.encode()
            )
            .test(
                .POST,
                "/api/users",
                headers: ["content-type": "application/json"],
                body: user2.encode()
            ) { res in
                XCTAssertEqual(res.status, .badRequest)
            }
            .test(
                .GET,
                "/api/users/\(userId)",
                headers: [
                    "Authorization": "\(user2.basicAuth())"
                ]
            ) { res in
                XCTAssertEqual(res.status, .unauthorized)
            }
            .test(
                .GET,
                "/api/users/\(userId)",
                headers: [
                    "Authorization": "\(user.basicAuth())"
                ]
                ) { res in
                    XCTAssertEqual(res.status, .ok)
                }
    }
    
    func testCreateAuthModifier() throws {
        let account = Account(name: "James' Bond")
        user1.id.map { account.$user.id = $0 }

        try tester()
            .test(
                .POST,
                "/api/accounts",
                headers: [
                    "content-type": "application/json",
                    "Authorization": "\(user2.bearerToken())"
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
                    "Authorization": "\(user1.bearerToken())"
                ],
                body: account.encode()
            ) { res in
                XCTAssertEqual(res.status, .ok)
            }
    }

    func testNestedAuthModifier() throws {
        try tester()
            .test(
                .GET,
                "/api/transactions/\(transactionId1)",
                headers: [
                    "Authorization": "\(user2.bearerToken())"
                ]
                ) { res in
                    XCTAssertEqual(res.status, .unauthorized)
                }
            .test(
                .GET,
                "/api/transactions/\(transactionId1)",
                headers: [
                    "Authorization": "\(user1.bearerToken())"
                ]
                ) { res in
                    XCTAssertEqual(res.status, .ok)
                }
    }

    func testNestedReadAllAuthModifier() throws {
        try tester()
            .test(
                .GET,
                "/api/transactions",
                headers: [
                    "Authorization": "\(user1.bearerToken())"
                ]
            ) { res in
                XCTAssertEqual(res.status, .unauthorized)
            }
            .test(
                .GET,
                "/api/transactions",
                headers: [
                    "Authorization": "\(user2.bearerToken())"
                ]
                ) { res in
                    let content = try res.content.decode([Transaction].self)
                    XCTAssertEqual(content.count, 1)
                }
       }

    func testNestedCreateAuthModifier() throws {
        let transaction = Transaction(
            amount: 40.0,
            currency: "GBP",
            date: Date()
        )
        
        transaction.$account.id = accountId1

        try tester()
            .test(
                .POST,
                "/api/transactions",
                headers: [
                    "content-type": "application/json",
                    "Authorization": "\(user2.bearerToken())"
                ],
                body: transaction.encode()
            ) { res in
                XCTAssertEqual(res.status, .unauthorized)
            }
            .test(
                .POST,
                "/api/transactions",
                headers: [
                    "content-type": "application/json",
                    "Authorization": "\(user1.bearerToken())"
                ],
                body: transaction.encode()
            ) { res in
                XCTAssertEqual(res.status, .ok)
            }
      }
    
    func testUpdateAuthModifier() throws {
        let update1 = Account(name: "Update1")
        user1.id.map { update1.$user.id = $0 }

        let update2 = Account(name: "Update2")
        user2.id.map { update2.$user.id = $0 }
        
        try tester()
            .test(
                .PUT,
                "/api/accounts/\(accountId1)",
                headers: [
                    "content-type": "application/json",
                    "Authorization": "\(user1.bearerToken())"
                ],
                body: update2.encode()
            ) { res in
                XCTAssertEqual(res.status, .unauthorized)
            }
            .test(
                .PUT,
                "/api/accounts/\(accountId1)",
                headers: [
                    "content-type": "application/json",
                    "Authorization": "\(user1.bearerToken())"
                ],
                body: update1.encode()
            ) { res in
                XCTAssertEqual(res.status, .ok)
            }
    }
}
