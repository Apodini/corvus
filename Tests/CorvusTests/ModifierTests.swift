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
                Custom<Account, Account>(pathComponents: "berzan", type: .get) {
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
        try tester()
            .test(.GET, "/api/accounts/\(accountId1)/transactions") { res in
                let content = try res.content.decode([Transaction].self)
                XCTAssertEqual(content, [transaction1])
        }
    }

    func testFilter() throws {
        try tester()
            .test(.GET, "/api/accounts") { res in
                let content = try res.content.decode([Account].self)
                XCTAssertEqual(content, [account2])
        }
    }

    func testResponseModifier() throws {
        let account = Account(name: "Respondant")
        user1.id.map { account.$user.id = $0 }
        let createRes = CreateResponse(item: account)
        let readRes = ReadResponse(item: [account1, account2, account])
        let customRes = CustomResponse(item: account1)

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
