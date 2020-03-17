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
}

extension DatabaseID {

    static var test: Self {
        .init(string: "test")
    }
}
