import Corvus
import Fluent
import FluentSQLiteDriver
import XCTVapor

final class ApplicationTests: XCTestCase {

    func testCreate() throws {
        final class CreateTest: RestApi {

            var content: Endpoint {
                Group("api", "accounts") {
                    Create<Account>()
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let createTest = CreateTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.migrations.add(CreateAccount())

        try app.autoMigrate().wait()
        
        try app.register(collection: createTest)
        
        let account = Account(name: "Berzan")
        try app.testable().test(
            .POST,
            "/api/accounts",
            headers: ["content-type": "application/json"],
            body: account.encode()
        ) { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqualJSON(res.body.string, account)
         }
    }

    func testReadOne() throws {
        final class ReadOneTest: RestApi {

            let testParameter = Parameter<Account>()

            var content: Endpoint {
                Group("api", "accounts") {
                    Create<Account>()

                    Group(testParameter.id) {
                        ReadOne<Account>(testParameter.id)
                    }
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let readOneTest = ReadOneTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.migrations.add(CreateAccount())

        try app.autoMigrate().wait()
        
        try app.register(collection: readOneTest)
        
        let account = Account(name: "Berzan")
        var accountRes: Account!
        try app.testable().test(
            .POST,
            "/api/accounts",
            headers: ["content-type": "application/json"],
            body: account.encode(),
            afterResponse: { res in
                accountRes = try res.content.decode(Account.self)
            }
        ).test(.GET, "/api/accounts/\(accountRes.id!)") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqualJSON(res.body.string, account)
        }
    }

    func testReadAll() throws {
        final class ReadAllTest: RestApi {

            var content: Endpoint {
                Group("api", "accounts") {
                    Create<Account>()
                    ReadAll<Account>()
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let readAllTest = ReadAllTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.migrations.add(CreateAccount())

        try app.autoMigrate().wait()

        try app.register(collection: readAllTest)
        
        let account1 = Account(name: "Berzan")
        let account2 = Account(name: "Paul")
        try app.testable().test(
            .POST,
            "/api/accounts",
            headers: ["content-type": "application/json"],
            body: account1.encode()
        ).test(
            .POST,
            "/api/accounts",
            headers: ["content-type": "application/json"],
            body: account2.encode()
        ).test(.GET, "/api/accounts/") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqualJSON(
                res.body.string,
                [account1, account2]
            )
        }
    }

    func testUpdate() throws {
        final class UpdateTest: RestApi {

            let testParameter = Parameter<Account>()

            var content: Endpoint {
                Group("api", "accounts") {
                    Create<Account>()

                    Group(testParameter.id) {
                        Update<Account>(testParameter.id)
                        ReadOne<Account>(testParameter.id)
                    }
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let updateTest = UpdateTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.migrations.add(CreateAccount())

        try app.autoMigrate().wait()

        try app.register(collection: updateTest)
        
        let account1 = Account(name: "Berzan")
        let account2 = Account(name: "Paul")
        var response: Account!
        
        try app.testable().test(
            .POST, "/api/accounts",
            headers: ["content-type": "application/json"],
            body: account1.encode(),
            afterResponse: { res in
                response = try res.content.decode(Account.self)
                XCTAssertEqualJSON(res.body.string, account1)
                }
        ).test(
            .PUT,
            "/api/accounts/\(response.id!)",
            headers: ["content-type": "application/json"],
            body: account2.encode()
        ).test(
            .GET,
            "/api/accounts/\(response.id!)"
        ) { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqualJSON(res.body.string, account2)
        }
    }

    func testDelete() throws {
        final class DeleteTest: RestApi {

            let testParameter = Parameter<Account>()

            var content: Endpoint {
                Group("api", "accounts") {
                    Create<Account>()

                    Group(testParameter.id) {
                        Delete<Account>(testParameter.id)
                    }
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let deleteTest = DeleteTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.migrations.add(CreateAccount())

        try app.autoMigrate().wait()

        try app.register(collection: deleteTest)
        
        let account = Account(name: "Berzan")
        var response: Account!
        
        try app.testable().test(
            .POST,
            "/api/accounts",
            headers: ["content-type": "application/json"],
            body: account.encode(),
            afterResponse: { res in
                response = try res.content.decode(Account.self)
            }
        ).test(.DELETE, "/api/accounts/\(response.id!)") { res in
            XCTAssertEqual(res.status, .ok)
        }
    }

    func testChildrenModifier() throws {
        final class ChildrenTest: RestApi {

            let testParameter = Parameter<Account>()

            var content: Endpoint {
                Group("api") {
                    Group("accounts") {
                        Create<Account>()

                        Group(testParameter.id) {
                            Group("transactions") {
                                ReadOne<Account>(testParameter.id)
                                    .children(\.$transactions)
                            }
                        }
                    }

                    Group("transactions") {
                        Create<Transaction>()
                    }
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let withTest = ChildrenTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.migrations.add(CreateAccount())
        app.migrations.add(CreateTransaction())

        try app.autoMigrate().wait()

        try app.register(collection: withTest)

        let account = Account(name: "Berzan")
        var accountRes: Account!
        var transaction: Transaction!

        try app.testable().test(
            .POST,
            "/api/accounts",
            headers: ["content-type": "application/json"],
            body: account.encode(),
            afterResponse: { res in
                accountRes = try res.content.decode(Account.self)
                transaction = Transaction(
                    amount: 40.0,
                    currency: "EUR",
                    date: Date(),
                    accountID: accountRes.id!
                )
            }
        ).test(
            .POST,
            "/api/transactions",
            headers: ["content-type": "application/json"],
            body: transaction.encode()
        ).test(.GET, "/api/accounts/\(accountRes.id!)/transactions") { res in
            let transactionRes = try res.content.decode([Transaction].self)
            XCTAssertEqual(transactionRes, [transaction])
        }
    }
    
     func testCustom() throws {
        final class CustomTest: RestApi {

            var content: Endpoint {
                Group("api", "accounts") {
                    Custom<Account>(path: "", type: .post) { req in
                        let requestContent = try req.content.decode(
                            Account.self
                        )
                        return requestContent.save(on: req.db)
                            .map { requestContent }
                    }
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let customTest = CustomTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.migrations.add(CreateAccount())

        try app.autoMigrate().wait()

        try app.register(collection: customTest)
        
        let account = Account(name: "Berzan")
        try app.testable().test(
            .POST,
            "/api/accounts",
            headers: ["content-type": "application/json"],
            body: account.encode()
        ) { res in
             XCTAssertEqual(res.status, .ok)
             XCTAssertEqualJSON(res.body.string, account)
         }
    }

    func testFilter() throws {
        final class FilterTest: RestApi {

            var content: Endpoint {
                Group("api", "accounts") {
                    Create<Account>()
                    ReadAll<Account>().filter(\.$name == "Paul")
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let filterTest = FilterTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.migrations.add(CreateAccount())
        try app.autoMigrate().wait()
        
        try app.register(collection: filterTest)
        
        let account1 = Account(name: "Berzan")
        let account2 = Account(name: "Paul")
        
        try app.testable().test(
            .POST,
            "/api/accounts",
            headers: ["content-type": "application/json"],
            body: account1.encode()
        ).test(
            .POST,
            "/api/accounts",
            headers: ["content-type": "application/json"],
            body: account2.encode()
        ).test(
            .GET,
            "/api/accounts"
        ) { res in
               XCTAssertEqual(res.status, .ok)
               XCTAssertEqualJSON(res.body.string, [account2])
        }
    }
    
    func testReadOneTrashed() throws {
        final class RestoreTest: RestApi {

            let testParameter = Parameter<Account>()

            var content: Endpoint {
                Group("api", "accounts") {
                    Create<Account>()
                    
                    Group(testParameter.id) {
                        Delete<Account>(testParameter.id)
                    }
                    
                    Group("trash", testParameter.id) {
                        ReadOne<Account>(testParameter.id, .trashed(\.$deletedAt))
                    }
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let readOneTest = RestoreTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.migrations.add(CreateAccount())

        try app.autoMigrate().wait()
        
        try app.register(collection: readOneTest)
        
        let account = Account(id: nil, name: "Berzan")
        var createdAccount: Account!
        
        struct AccountResponse: Codable {
            let id: Account.IDValue
            let name: String
            let deletedAt: String
        }
        
        try app.testable()
            .test(.POST, "/api/accounts", headers: ["content-type": "application/json"], body: account.encode(), afterResponse: { res in
            createdAccount = try res.content.decode(Account.self)
            })
            .test(.DELETE, "/api/accounts/\(createdAccount.id!)")
            .test(.GET, "/api/accounts/trash/\(createdAccount.id!)", afterResponse: { res in
                let accountResponse = try res.content.decode(AccountResponse.self)
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(createdAccount.name, accountResponse.name)
            })
            .test(.GET, "/api/accounts/\(createdAccount.id!)", afterResponse: { res in
                XCTAssertEqual(res.status, .notFound)
            })
    }
        
    func testReadAllTrashed() throws {
        final class ReadAllTrashedTest: RestApi {

            let testParameter = Parameter<Account>()

            var content: Endpoint {
                Group("api", "accounts") {
                    Create<Account>()
                    ReadAll<Account>()
                    
                    Group(testParameter.id) {
                        Delete<Account>(testParameter.id)
                    }
                    
                    Group("trash") {
                        ReadAll<Account>(.trashed(\.$deletedAt))
                    }
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let readAllTrashedTest = ReadAllTrashedTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.migrations.add(CreateAccount())

        try app.autoMigrate().wait()
        
        try app.register(collection: readAllTrashedTest)
        
        let account = Account(id: nil, name: "Berzan")
        var createdAccount: Account!
        
        struct AccountResponse: Codable {
            let id: Account.IDValue
            let name: String
            let deletedAt: String
        }
        
        try app.testable()
            .test(.POST, "/api/accounts", headers: ["content-type": "application/json"], body: account.encode(), afterResponse: { res in
            createdAccount = try res.content.decode(Account.self)
            })
            .test(.DELETE, "/api/accounts/\(createdAccount.id!)")
            .test(.GET, "/api/accounts/trash/", afterResponse: { res in
                let response = try res.content.decode([AccountResponse].self)
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(account.name, response.first!.name)
            })
            .test(.GET, "/api/accounts/", afterResponse: { res in
                XCTAssertEqual(res.body.string, "[]")
            })
    }
        
    func testRestore() throws {
        final class RestoreTest: RestApi {

            let testParameter = Parameter<Account>()

            var content: Endpoint {
                Group("api", "accounts") {
                    Create<Account>()
                    
                    Group(testParameter.id) {
                        ReadOne<Account>(testParameter.id)
                        Delete<Account>(testParameter.id)
                    }
                    
                    Group("trash", testParameter.id) {
                        Restore<Account>(testParameter.id, deletedAtKey: \.$deletedAt)
                    }
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let readOneTest = RestoreTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.migrations.add(CreateAccount())

        try app.autoMigrate().wait()
        
        try app.register(collection: readOneTest)
        print(app.routes.all)
        let account = Account(id: nil, name: "Berzan")
        var AccountRes: Account!
        
        try app.testable()
            .test(.POST, "/api/accounts", headers: ["content-type": "application/json"], body: account.encode()) { res in
                AccountRes = try res.content.decode(Account.self)
            }
            .test(.GET, "/api/accounts/\(AccountRes.id!)") { res in
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqualJSON(res.body.string, account)
            }
            .test(.DELETE, "/api/accounts/\(AccountRes.id!)") { res in
                XCTAssertEqual(res.status, .ok)
            }
            .test(.GET, "/api/accounts/\(AccountRes.id!)") { res in
                XCTAssertEqual(res.status, .notFound)
            }
            .test(.PATCH, "/api/accounts/trash/\(AccountRes.id!)") { res in
                XCTAssertEqual(res.status, .ok)
            }
            .test(.GET, "/api/accounts/\(AccountRes.id!)") { res in
                print(res.body.string)
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqualJSON(res.body.string, account)
            }
    }
    
    func testDeleteTrashed() throws {
        final class DeleteTrashedTest: RestApi {

            let testParameter = Parameter<Account>()

            var content: Endpoint {
                Group("api", "accounts") {
                    Create<Account>()
                    ReadAll<Account>()
                    
                    Group(testParameter.id) {
                        Delete<Account>(testParameter.id)
                    }
                    
                    Group("trash") {
                        ReadAll<Account>(.trashed(\.$deletedAt))
                        Group(testParameter.id) {
                            Delete<Account>(testParameter.id, .trashed(\.$deletedAt))
                        }
                    }
                }
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }
        let deleteTrashedTest = DeleteTrashedTest()

        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
        app.migrations.add(CreateAccount())

        try app.autoMigrate().wait()
        
        try app.register(collection: deleteTrashedTest)
        
        let account = Account(id: nil, name: "Berzan")
        var createdAccount: Account!
        
        try app.testable()
            .test(.POST, "/api/accounts", headers: ["content-type": "application/json"], body: account.encode(), afterResponse: { res in
                createdAccount = try res.content.decode(Account.self)
            })
            .test(.DELETE, "/api/accounts/\(createdAccount.id!)")
            .test(.GET, "/api/accounts/trash/", afterResponse: { res in
                XCTAssertNotEqual(res.body.string, "[]")
            })
            .test(.DELETE, "/api/accounts/trash/\(createdAccount.id!)", afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
            })
            .test(.GET, "/api/accounts/trash", afterResponse: { res in
                XCTAssertEqual(res.body.string, "[]")
            })
    }
}

extension DatabaseID {

    static var test: Self {
        .init(string: "test")
    }
}
