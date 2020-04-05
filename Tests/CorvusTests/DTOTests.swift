import Corvus
import Fluent
import FluentSQLiteDriver
import XCTVapor
import Foundation

struct AccountCreateDTO: CreateDTO {
    init() {}
    
    typealias Element = Account
    
    @ConnectField(to: \.$name)
    var name: String

    @ConnectChildren(to: \.$transactions)
    var transactions: [Transaction]
    
    @ConnectParent(to: \.$user)
    var user: CorvusUser.IDValue
}

final class DTOTests: CorvusTests {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let accountParameter = Parameter<Account>().id
        
        let api = Api("api", "accounts") {
            Create<Account>()
                .mediator(AccountCreateDTO.self)

            Group(accountParameter) {
                Update<Account>(accountParameter)
            }
        }
        
        try app.register(collection: api)
    }
    
    func testCreateDTO() throws {
        
    }

}
