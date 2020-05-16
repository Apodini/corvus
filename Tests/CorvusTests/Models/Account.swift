import Corvus
import Fluent
import Foundation

final class Account: CorvusModel {

    static let schema = "accounts"

    @ID
    var id: UUID? {
        didSet {
              if id != nil {
                  $id.exists = true
              }
          }
    }

    @Field(key: "name")
    var name: String

    @Children(for: \.$account)
    var transactions: [Transaction]

    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }

    init() {}
}

struct CreateAccount: Migration {

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Account.schema)
        .id()
        .field("name", .string, .required)
        .field("deleted_at", .date)
        .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Account.schema).delete()
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
