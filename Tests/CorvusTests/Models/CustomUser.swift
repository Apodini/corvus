import Corvus
import Fluent
import Vapor
import Foundation

public final class CustomUser: CorvusModel {

    public static let schema = "custom_users"

    @ID
    public var id: UUID?

    @Field(key: "name")
    public var name: String
    
    @Field(key: "surname")
    public var surname: String

    @Field(key: "email")
    public var email: String

    @Field(key: "password_hash")
    public var passwordHash: String

    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    public init() { }

    public init(
        id: UUID? = nil,
        name: String,
        surname: String,
        email: String,
        passwordHash: String
    ) {
        self.id = id
        self.name = name
        self.surname = surname
        self.email = email
        self.passwordHash = passwordHash
    }
}

public struct CreateCustomUser: Migration {

    public init() {}

    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CustomUser.schema)
            .id()
            .field("name", .string, .required)
            .field("surname", .string, .required)
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .field("deleted_at", .date)
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CustomUser.schema).delete()
    }
}

extension CustomUser: CorvusModelUser {

    public static let usernameKey = \CustomUser.$name

    public static let passwordHashKey = \CustomUser.$passwordHash

    public func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

extension CustomUser {

    public func generateToken() throws -> CorvusToken {
        try .init(
            value: [UInt8].random(count: 16).base64,
            userID: self.requireID()
        )
    }
}
