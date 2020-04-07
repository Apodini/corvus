import Corvus
import Foundation
import Fluent

public final class CustomToken: CorvusModelUserToken {

    public static let schema = "custom_tokens"

    @ID
    public var id: UUID?

    @Field(key: "value")
    public var value: String

    @Parent(key: "user_id")
    public var user: CustomUser

    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    public init() { }


    public init(id: UUID? = nil, value: String, userID: CustomUser.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
}

public struct CreateCustomToken: Migration {

    public init() {}

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CustomToken.schema)
            .id()
            .field("value", .string, .required)
            .field(
                "user_id",
                .uuid,
                .required,
                .references(CustomUser.schema, .id)
            )
            .field("deleted_at", .date)
            .unique(on: "value")
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CustomToken.schema).delete()
    }
}

extension CustomToken {

    public var isValid: Bool {
        true
    }
}
