import Vapor
import Fluent

// swiftlint:disable identifier_name

/// A protocol that defines bearer authentication tokens, similar to
/// `ModelAuthenticatable`.
public protocol CorvusModelAuthenticatable: CorvusModel, Authenticatable {
    
    /// The name of the user.
    var username: String { get set }
    
    /// The hashed password of the user.
    var password: String { get set }
    
    /// A function to verify a given password against the user's.
    func verify(password: String) throws -> Bool
}

/// An extension to provide an authenticator for the user that can be
/// registered to the `Vapor` application, and field accessors for `username` and
/// `password`.
extension CorvusModelAuthenticatable {

    /// Provides a `Vapor` authenticator defined below.
    /// - Parameter database: The database to authenticate.
    /// - Returns: A `CorvusModelAuthenticator`.
    public static func authenticator(
        database: DatabaseID? = nil
    ) -> CorvusModelAuthenticator<Self> {
        CorvusModelAuthenticator<Self>(database: database)
    }

    /// Provides access to the `username` attribute.
    var _$username: Field<String> {
        guard let mirror = Mirror(reflecting: self).descendant("_username"),
            let username = mirror as? Field<String> else {
                fatalError("username property must be declared using @Field")
        }

        return username
    }

    /// Provides access to the `password` attribute.
    var _$password: Field<String> {
        guard let mirror = Mirror(reflecting: self).descendant("_password"),
            let password = mirror as? Field<String> else {
                fatalError("password property must be declared using @Parent")
        }

        return password
    }
}

/// Provides a `BasicAuthenticator` struct that defines how users are
/// authenticated.
public struct CorvusModelAuthenticator<User: CorvusModelAuthenticatable>:
    BasicAuthenticator
{
    /// The database the user is saved in.
    public let database: DatabaseID?

    /// Authenticates a user.
    /// - Parameters:
    ///   - basic: The username and password passed in the request.
    ///   - request: The `Request` to be authenticated.
    /// - Returns: An empty `EventLoopFuture`.
    public func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
        User.query(on: request.db(self.database))
            .filter(\User._$username == basic.username)
            .first()
            .flatMapThrowing
        {
            guard let user = $0 else {
                return
            }
            guard try user.verify(password: basic.password) else {
                return
            }
            request.auth.login(user)
        }
    }
}
