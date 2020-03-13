import Corvus
import Fluent

final class Account: CorvusModel {

    static let schema = "accounts"

    @ID
    var id: UUID? {
        didSet {
            $id.exists = true
        }
    }

    @Field(key: "name")
    var name: String

    @Children(for: \.$account)
    var transactions: [Transaction]

    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }

    init() {}
}

extension Account {
    struct CreateAccountMigration: Fluent.Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                return database.schema(Account.schema)
                .id()
                .field("name", .string, .required)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            return database.schema(Account.schema).delete()
        }
    }
}

extension Account: Equatable {
    static func == (lhs: Account, rhs: Account) -> Bool {
        var result = lhs.name == rhs.name
        
        if let lhsId = lhs.id, let rhsId = rhs.id {
            result = result && lhsId == rhsId
        }
        
        return result
    }
}
