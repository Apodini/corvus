import Corvus
import Fluent
import FluentSQLiteDriver
import XCTVapor
import Foundation

// This is a basic response.
struct CreateResponse: CorvusResponse, Equatable {
    let created = true
    let name: String

    init(item: Account) {
        self.name = item.name
    }
}

// This response is a more complex example using generics.
// This allows for responses which work with any number of models.
struct ReadResponse<Model: AnyModel & Equatable>: CorvusResponse, Equatable {
    let success = true
    let payload: [Model]

    init(item: [Model]) {
        payload = item
    }
}

struct CustomResponse: CorvusResponse, Equatable {
    let name: String

    init(item: Account) {
        name = item.name
    }
}

final class ModifierTests: CorvusTests {
        
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let accountParameter = Parameter<Account>().id
        
        let api = Api("api") {
            Group("respond") {
                Create<Account>().respond(with: CreateResponse.self)
                ReadAll<Account>().respond(with: ReadResponse.self)
                Custom<Account>(pathComponents: "berzan", type: .get) {
                    Account
                        .query(on: $0.db)
                        .first()
                        .unwrap(or: Abort(.notFound))
                }.respond(with: CustomResponse.self)
            }
            
            Group("accounts") {
                Create<Account>()
                ReadAll<Account>().filter(\.$name == "Paul's Wallet")

                Group(accountParameter) {
                    Group("transactions") {
                        ReadOne<Account>(accountParameter)
                            .children(\.$transactions)
                    }
                }
            }
            
            Group("transactions") {
                Create<Transaction>()
            }
        }
        
        try app.register(collection: api)
    }
    

    func testChildrenModifier() throws {
        let account = Account(name: "Berzan's Wallet")
        try account.create(on: database()).wait()
        let accountId = try XCTUnwrap(account.id)
        
        let transaction = Transaction(
            amount: 40.0,
            currency: "EUR",
            date: Date(),
            accountID: accountId
        )
        try transaction.create(on: database()).wait()

        try tester()
            .test(.GET, "/api/accounts/\(accountId)/transactions") { res in
                let content = try res.content.decode([Transaction].self)
                XCTAssertEqual(content, [transaction])
        }
    }

    func testFilter() throws {
        let account1 = Account(name: "Berzan's Wallet")
        try account1.create(on: database()).wait()
         
        let account2 = Account(name: "Paul's Wallet")
        try account2.create(on: database()).wait()

        try tester()
            .test(.GET, "/api/accounts") { res in
                let content = try res.content.decode([Account].self)
                XCTAssertEqual(content, [account2])
        }
    }

    func testResponseModifier() throws {
        let account = Account(name: "Berzan's Wallet")
        let createRes = CreateResponse(item: account)
        let readRes = ReadResponse(item: [account])
        let customRes = CustomResponse(item: account)

        try tester()
            .test(
                .POST,
                "/api/respond",
                headers: ["content-type": "application/json"],
                body: account.encode(),
                afterResponse: { res in
                    XCTAssertEqualJSON(res.body.string, createRes)
                }
            ).test(.GET, "/api/respond") { res in
                XCTAssertEqualJSON(res.body.string, readRes)
            }.test(.GET, "/api/respond/berzan") { res in
                XCTAssertEqualJSON(res.body.string, customRes)
            }
    }
}
