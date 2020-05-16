import Corvus
import Fluent
import FluentSQLiteDriver
import XCTVapor
import Foundation

final class CrudTests: CorvusTests {
        
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let accountParameter = Parameter<Account>().id
        
        let api = Api("api") {
            Group("accounts") {
                Create<Account>()
                ReadAll<Account>()

                Group(accountParameter) {
                    ReadOne<Account>(accountParameter)
                    Update<Account>(accountParameter)
                    Delete<Account>(accountParameter)
                }
            }
            
            Group("custom") {
                Custom<Account>(
                    pathComponents: "id",
                    type: .post
                ) { req in
                    let requestContent = try req.content.decode(
                        Account.self
                    )
                    return requestContent.save(on: req.db)
                        .map { requestContent }
                }
            }
        }
        
        try app.register(collection: api)
    }

    func testCreate() throws {
        let account = Account(name: "Berzan's Wallet")

        try tester()
            .test(
                .POST,
                "/api/accounts",
                headers: ["content-type": "application/json"],
                body: account.encode()
            ) { res in
                let content = try res.content.decode(Account.self)
                XCTAssertEqual(content, account)
            }
    }

    func testReadOne() throws {
        let account = Account(name: "Berzan's Wallet")
        try account.create(on: database()).wait()
        let accountId = try XCTUnwrap(account.id)

        try tester()
            .test(.GET, "/api/accounts/\(accountId)") { res in
                let content = try res.content.decode(Account.self)
                XCTAssertEqual(content, account)
            }
    }

    func testReadAll() throws {
        let account1 = Account(name: "Berzan's Wallet")
        try account1.create(on: database()).wait()
        
        let account2 = Account(name: "Paul's Wallet")
        try account2.create(on: database()).wait()
        
        try tester()
            .test(.GET, "/api/accounts/") { res in
                let content = try res.content.decode([Account].self)
                XCTAssertEqual(content, [account1, account2])
            }
    }

    func testUpdate() throws {
        let account1 = Account(name: "Berzan's Wallet")
        let account2 = Account(name: "Paul's Wallet")
        try account1.create(on: database()).wait()
        let accountId1 = try XCTUnwrap(account1.id)

        try tester()
            .test(
                .PUT,
                "/api/accounts/\(accountId1)",
                headers: ["content-type": "application/json"],
                body: account2.encode()
            ).test(.GET, "/api/accounts/\(accountId1)") { res in
                let content = try res.content.decode(Account.self)
                XCTAssertEqual(content, account2)
            }
    }

    func testDelete() throws {
        let account = Account(name: "Berzan's Wallet")
        try account.create(on: database()).wait()
        let accountId = try XCTUnwrap(account.id)
        
        try tester()
            .test(.DELETE, "/api/accounts/\(accountId)") { res in
                XCTAssertEqual(res.status, .ok)
            }
    }
    
    func testCustom() throws {
        let account = Account(name: "Berzan's Wallet")

        try tester()
            .test(
                .POST,
                "/api/custom/id",
                headers: ["content-type": "application/json"],
                body: account.encode()
            ) { res in
                 let content = try res.content.decode(Account.self)
                 XCTAssertEqual(content, account)
            }
    }
}
