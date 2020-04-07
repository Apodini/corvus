import Vapor
import Fluent

/// A default implementation of a bearer token.
public final class CorvusToken: CorvusModelUserToken {

    /// The corresponding database schema.
    public static let schema = "corvus_tokens"

    /// The unique identifier of the model in the database.
    @ID
    public var id: UUID?

    /// The string value of the token.
    @Field(key: "value")
    public var value: String

    /// The `CorvusUser` that the token belongs to.
    @Parent(key: "user_id")
    public var user: CorvusUser

    /// Timestamp for soft deletion.
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    /// Empty initializer to create without args.
    public init() { }


    /// Initializes `CorvusToken` with arguments.
    /// - Parameters:
    ///   - id: The id of the `CorvusToken`.
    ///   - value: The `string` value of the `CorvusToken`.
    ///   - userID: The id of the `CorvusUser` the `CorvusToken` belongs to.
    public init(id: UUID? = nil, value: String, userID: CorvusUser.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
}

/// A struct to provide a database migration.
public struct CreateCorvusToken: Migration {

    /// An empty initializer to provide public initialization.
    public init() {}

    /// Prepares database fields and their value types.
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CorvusToken.schema)
            .id()
            .field("value", .string, .required)
            .field(
                "user_id",
                .uuid,
                .required,
                .references(CorvusUser.schema, .id)
            )
            .field("deleted_at", .date)
            .unique(on: "value")
            .create()
    }

    /// Implements functionality to delete schema when database is reverted.
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CorvusToken.schema).delete()
    }
}

/// An extension to conform to the `ModelUserToken` protocol, which provides
/// functionality to authenticate a token.
extension CorvusToken {

    /// Prevents tokens from being deleted after authentication.
    public var isValid: Bool {
        true
    }
}
