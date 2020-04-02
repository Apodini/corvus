import Corvus
import Fluent
import Foundation

final class SecureAccount: CorvusModel {

    static let schema = "accounts"

    @ID
    var id: UUID? {
        didSet {
            $id.exists = true
        }
    }

    @Field(key: "name")
    var name: String

    @Parent(key: "user_id")
    var user: CorvusUser

    @Children(for: \.$account)
    var transactions: [SecureTransaction]

    init(id: UUID? = nil, name: String, userID: CorvusUser.IDValue) {
        self.id = id
        self.name = name
        self.$user.id = userID
    }

    init() {}
}

struct CreateSecureAccount: Migration {

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(SecureAccount.schema)
        .id()
        .field("name", .string, .required)
        .field(
            "user_id",
            .uuid,
            .references(CorvusUser.schema, "id")
        )
        .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(SecureAccount.schema).delete()
    }
}

extension SecureAccount: Equatable {
    static func == (lhs: SecureAccount, rhs: SecureAccount) -> Bool {
        var result = lhs.name == rhs.name

        if let lhsId = lhs.id, let rhsId = rhs.id {
            result = result && lhsId == rhsId
        }

        return result
    }
}
