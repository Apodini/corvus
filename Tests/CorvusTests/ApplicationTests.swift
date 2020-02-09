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
        app.migrations.add(Account.Migration())

        try app.autoMigrate().wait()

        try app.register(collection: createTest)
        try app.testable().test(.POST, "/api/accounts", json: [
            "name": "Berzan",
        ]) { res in
             XCTAssertEqual(res.status, .ok)
             XCTAssertEqual(res.body.string, "{\"id\":1,\"name\":\"Berzan\"}")
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
        app.migrations.add(Account.Migration())

        try app.autoMigrate().wait()

        try app.register(collection: readOneTest)
        try app.testable().test(.POST, "/api/accounts", json: [
            "name": "Berzan",
        ]).test(.GET, "/api/accounts/1") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "{\"id\":1,\"name\":\"Berzan\"}")
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
        app.migrations.add(Account.Migration())

        try app.autoMigrate().wait()

        try app.register(collection: readAllTest)
        try app.testable().test(.POST, "/api/accounts", json: [
            "name": "Berzan",
        ]).test(.POST, "/api/accounts", json: [
            "name": "Paul"
        ]).test(.GET, "/api/accounts/") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(
                res.body.string,
                "[{\"id\":1,\"name\":\"Berzan\"},{\"id\":2,\"name\":\"Paul\"}]")
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
        app.migrations.add(Account.Migration())

        try app.autoMigrate().wait()

        try app.register(collection: updateTest)
        try app.testable().test(.POST, "/api/accounts", json: [
            "name": "Berzan",
        ]).test(.PUT, "/api/accounts/1", json: [
            "name": "Paul",
        ]).test(.GET, "/api/accounts/1") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "{\"id\":1,\"name\":\"Paul\"}")
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
        app.migrations.add(Account.Migration())

        try app.autoMigrate().wait()

        try app.register(collection: deleteTest)
        try app.testable().test(.POST, "/api/accounts", json: [
            "name": "Berzan",
        ]).test(.DELETE, "/api/accounts/1") { res in
            XCTAssertEqual(res.status, .ok)
        }
    }

//    func testWith() throws {
//        final class WithTest: RestApi {
//
//            let testParameter = Parameter<Account>()
//
//            var content: Endpoint {
//                Group("api") {
//                    Group("accounts") {
//                        Create<Account>()
//
//                        Group(testParameter.id) {
//                            Group("transactions") {
//                                ReadOne<Account>(testParameter.id).with(\.$transactions)
//                            }
//                        }
//                    }
//
//                    Group("transactions") {
//                        Create<Transaction>()
//                    }
//                }
//            }
//        }
//
//        let app = Application(.testing)
//        defer { app.shutdown() }
//        let withTest = WithTest()
//
//        app.databases.use(.sqlite(.memory), as: .test, isDefault: true)
//        app.migrations.add(Account.Migration())
//        app.migrations.add(Transaction.Migration())
//
//        try app.autoMigrate().wait()
//
//        let transaction = Transaction(
//            id: 1,
//            amount: 40.0,
//            currency: "EUR",
//            date: Date(),
//            accountId: 1
//        )
//
//        try app.register(collection: withTest)
//        try app.testable()
//            .test(
//                .POST,
//                "/api/accounts",
//                json: [
//                    "name": "Berzan",
//                ]
//            )
//            .test(
//                .POST,
//                "/api/transactions",
//                json: transaction
//            )
//            .test(.GET, "/api/accounts/1/transactions") { res in
//                print(res.body.string)
//            }
//    }
    
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
        app.migrations.add(Account.Migration())

        try app.autoMigrate().wait()

        try app.register(collection: customTest)
        try app.testable().test(.POST, "/api/accounts", json: [
            "name": "Berzan",
        ]) { res in
             XCTAssertEqual(res.status, .ok)
             XCTAssertEqual(res.body.string, "{\"id\":1,\"name\":\"Berzan\"}")
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
        app.migrations.add(Account.Migration())

        try app.autoMigrate().wait()

        try app.register(collection: filterTest)
        try app.testable().test(.POST, "/api/accounts", json: [
               "name": "Berzan",
           ]).test(.POST, "/api/accounts", json: [
               "name": "Paul",
           ]).test(.GET, "/api/accounts") { res in
               XCTAssertEqual(res.status, .ok)
               XCTAssertEqual(res.body.string, "[{\"id\":2,\"name\":\"Paul\"}]")
           }
    }
}

extension DatabaseID {

    static var test: Self {
        .init(string: "test")
    }
}
