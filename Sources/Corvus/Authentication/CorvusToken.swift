import Vapor
import Fluent

/// A default implementation of a bearer token.
public final class CorvusToken: CorvusModel {

    /// The corresponding database schema.
    public static let schema = "tokens"

    /// The unique identifier of the model in the database.
    @ID
    public var id: UUID?

    /// The string value of the token.
    @Field(key: "value")
    public var value: String

    /// The `CorvusUser` that the token belongs to.
    @Parent(key: "user_id")
    public var user: CorvusUser

    public init() { }

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
extension CorvusToken: ModelUserToken {

    /// Makes the path to a token's value publicly accessible.
    public static let valueKey = \CorvusToken.$value

    /// Makes the path to a token's user publicly accessible.
    public static let userKey = \CorvusToken.$user

    /// Prevents tokens from being deleted after authentication.
    public var isValid: Bool {
        true
    }
}
