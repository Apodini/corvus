import Vapor
import Fluent

/// A default implementation of a user for basic authentication.
public final class CorvusUser: CorvusModel {

    /// The corresponding database schema.
    public static let schema = "corvus_users"

    /// The unique identifier of the model in the database.
    @ID
    public var id: UUID?

    /// The name of the user.
    @Field(key: "username")
    public var username: String

    /// The hashed password of the user, used during authentication.
    @Field(key: "password_hash")
    public var passwordHash: String

    /// Timestamp for soft deletion.
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    /// Provides public access to the User's initializer.
    public init() { }

    /// Creates a user with its given properties.
    ///
    /// - Parameters:
    ///     - id: The identifier of the user, auto generated if not provided.
    ///     - username: The username of the user.
    ///     - passwordHash: The hashed password of the user.
    public init(
        id: UUID? = nil,
        username: String,
        passwordHash: String
    ) {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
    }
}

/// Provides a migration structure for databases with schemas.
public struct CreateCorvusUser: Migration {

    /// An empty initializer without args.
    public init() {}

    /// Prepares database fields and their value types.
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CorvusUser.schema)
            .id()
            .field("username", .string, .required)
            .field("password_hash", .string, .required)
            .field("deleted_at", .date)
            .create()
    }

    /// Implements functionality to delete schema when database is reverted.
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CorvusUser.schema).delete()
    }
}

/// An extension to conform to the `CorvusModelUser` protocol, which provides
/// functionality to authenticate a user with username and password.
extension CorvusUser: CorvusModelAuthenticatable {
    
    /// Provides a path to the user's username.
    public static let usernameKey = \CorvusUser.$username

    /// Provides a path to the user's hashed password.
    public static let passwordHashKey = \CorvusUser.$passwordHash

    /// Verifies a given string by checking if it matches a user's password.
    ///
    /// - Parameter password: The password to verify.
    /// - Returns: True if the provided password matches the user's, false if
    /// not.
    public func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
