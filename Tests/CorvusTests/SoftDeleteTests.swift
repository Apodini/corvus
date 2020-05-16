import Corvus
import Fluent
import FluentSQLiteDriver
import XCTVapor
import Foundation

final class SoftDeleteTests: CorvusTests {
        
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let accountParameter = Parameter<Account>().id
        
        let api = Api("api") {
            Group("accounts") {
                ReadAll<Account>()

                Group(accountParameter) {
                    ReadOne<Account>(accountParameter)
                    Delete<Account>(accountParameter)
                }
                
                Group("trash") {
                    Group(accountParameter) {
                        ReadOne<Account>(accountParameter, .trashed)
                        Delete<Account>(accountParameter, softDelete: true)
                        
                        Group("restore") {
                            Restore<Account>(accountParameter)
                        }
                    }
                    
                    ReadAll<Account>(.trashed)
                }
                
                Group("existing") {
                    Group(accountParameter) {
                        ReadOne<Account>(accountParameter, .existing)
                    }
                    
                    ReadAll<Account>(.existing)
                }

                Group("all") {
                    Group(accountParameter) {
                        ReadOne<Account>(accountParameter, .all)
                    }
                    
                    ReadAll<Account>(.all)
                }
            }
        }
        
        try app.register(collection: api)
    }
    
    func testRestore() throws {
        let account = Account(name: "Berzan's Wallet")
        try account.create(on: database()).wait()
        let accountId = try XCTUnwrap(account.id)

        try tester()
            .test(.DELETE, "/api/accounts/trash/\(accountId)") { res in
                XCTAssertEqual(res.status, .ok)
            }.test(.GET, "/api/accounts/\(accountId)") { res in
                XCTAssertEqual(res.status, .notFound)
            }.test(.PATCH, "/api/accounts/trash/\(accountId)/restore") { res in
                XCTAssertEqual(res.status, .ok)
            }.test(.GET, "/api/accounts/\(accountId)") { res in
                let content = try res.content.decode(Account.self)
                XCTAssertEqual(content, account)
            }
    }
    
    func testReadAllTrashed() throws {
        let account1 = Account(name: "Berzan's Wallet")
        try account1.create(on: database()).wait()
        let accountId1 = try XCTUnwrap(account1.id)
        
        let account2 = Account(name: "Paul's Wallet")
        try account2.create(on: database()).wait()
        
        try tester()
            .test(.DELETE, "/api/accounts/trash/\(accountId1)")
            .test(.GET, "/api/accounts") { res in
                let response = try res.content.decode([Account].self)
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(response, [account2])
            }
            .test(.GET, "/api/accounts/existing") { res in
                let response = try res.content.decode([Account].self)
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(response, [account2])
            }
            .test(.GET, "/api/accounts/all") { res in
                let response = try res.content.decode([Account].self)
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(response, [account1, account2])
            }
            .test(.GET, "/api/accounts/trash") { res in
                let response = try res.content.decode([Account].self)
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(response, [account1])
            }
    }

    func testReadOneTrashed() throws {
        let account = Account(name: "Berzan's Wallet")
        try account.create(on: database()).wait()
        let accountId = try XCTUnwrap(account.id)

        try tester()
            .test(.GET, "/api/accounts/\(accountId)") { res in
                let content = try res.content.decode(Account.self)
                XCTAssertEqual(content, account)
            }.test(.GET, "/api/accounts/existing/\(accountId)") { res in
                let content = try res.content.decode(Account.self)
                XCTAssertEqual(content, account)
            }.test(.DELETE, "/api/accounts/trash/\(accountId)")
            .test(.GET, "/api/accounts/existing/\(accountId)") { res in
                XCTAssertEqual(res.status, .notFound)
            }.test(.GET, "/api/accounts/all/\(accountId)") { res in
                let content = try res.content.decode(Account.self)
                XCTAssertEqual(content, account)
            }.test(.GET, "/api/accounts/trash/\(accountId)") { res in
                let content = try res.content.decode(Account.self)
                XCTAssertEqual(content, account)
            }
    }

    func testDeleteTrashed() throws {
        let account = Account(name: "Berzan's Wallet")
        try account.create(on: database()).wait()
        let accountId = try XCTUnwrap(account.id)

        try tester()
            .test(.DELETE, "/api/accounts/trash/\(accountId)")
            .test(.GET, "/api/accounts/trash/\(accountId)") { res in
                let content = try res.content.decode(Account.self)
                XCTAssertEqual(content, account)
            }
            .test(.DELETE, "/api/accounts/\(accountId)")
            .test(.GET, "/api/accounts/trash/\(accountId)") { res in
                XCTAssertEqual(res.status, .notFound)
            }
    }
}
