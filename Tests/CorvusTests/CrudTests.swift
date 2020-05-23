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
                    Delete<SoloAccount>(accountParameter)
                }
            }
            
            Group("custom") {
                Custom<Account, Account>(
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
        let account = Account(name: "Creator")
        user1.id.map { account.$user.id = $0 }
        
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
        try tester()
            .test(.GET, "/api/accounts/\(accountId1)") { res in
                let content = try res.content.decode(Account.self)
                XCTAssertEqual(content, account1)
            }
    }

    func testReadAll() throws {
        try tester()
            .test(.GET, "/api/accounts/") { res in
                let content = try res.content.decode([Account].self)
                XCTAssertEqual(content, [account1, account2])
            }
    }
    
    func testDelete() throws {
        let account = SoloAccount(name: "Delete")
        try account.create(on: database()).wait()
        let accountId = try XCTUnwrap(account.id)
        
        try tester()
            .test(.DELETE, "/api/accounts/\(accountId)") { res in
                XCTAssertEqual(res.status, .ok)
            }
    }

    func testUpdate() throws {
        let update = Account(name: "Update")
        user1.id.map { update.$user.id = $0 }

        try tester()
            .test(
                .PUT,
                "/api/accounts/\(accountId1)",
                headers: ["content-type": "application/json"],
                body: update.encode()
            ).test(.GET, "/api/accounts/\(accountId1)") { res in
                let content = try res.content.decode(Account.self)
                XCTAssertEqual(content, update)
            }
    }
    
    func testCustom() throws {
        let account = Account(name: "Creator")
        user1.id.map { account.$user.id = $0 }

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
