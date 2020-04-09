import Corvus
import Fluent
import Foundation

final class CustomAccount: CorvusModel {

    static let schema = "custom_accounts"

    @ID
    var id: UUID? {
        didSet {
            $id.exists = true
        }
    }

    @Field(key: "name")
    var name: String

    @Parent(key: "user_id")
    var user: CustomUser

    @Children(for: \.$account)
    var transactions: [CustomTransaction]

    init(id: UUID? = nil, name: String, userID: CustomUser.IDValue) {
        self.id = id
        self.name = name
        self.$user.id = userID
    }

    init() {}
}

struct CreateCustomAccount: Migration {

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(CustomAccount.schema)
        .id()
        .field("name", .string, .required)
        .field(
            "user_id",
            .uuid,
            .references(CustomUser.schema, "id")
        )
        .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(CustomAccount.schema).delete()
    }
}

extension CustomAccount: Equatable {
    static func == (lhs: CustomAccount, rhs: CustomAccount) -> Bool {
        var result = lhs.name == rhs.name

        if let lhsId = lhs.id, let rhsId = rhs.id {
            result = result && lhsId == rhsId
        }

        return result
    }
}
