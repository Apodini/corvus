import Corvus
import Fluent

final class Account: CorvusModel {

    static let schema = "accounts"

    @ID(key: "id")
    var id: Int? {
        didSet {
            $id.exists = true
        }
    }

    @Field(key: "name")
    var name: String

    @Children(for: \.$account)
    var transactions: [Transaction]

    init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
    }

    init() {}
}

extension Account {
    struct Migration: Fluent.Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("accounts")
                .field("id", .int, .identifier(auto: true))
                .field("name", .string, .required)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("accounts").delete()
        }
    }
}
