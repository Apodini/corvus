import Vapor
import Fluent

// swiftlint:disable identifier_name

/// A protocol that defines bearer authentication tokens, similar to
/// `CorvusModelTokenAuthenticatable`.
public protocol CorvusModelTokenAuthenticatable: CorvusModel, Authenticatable {
    /// The `User` type the token belongs to.
     associatedtype User: CorvusModel & Authenticatable

     /// The `String` value of the token.
     var value: String { get set }

     /// The `User` associated with the token.
     var user: User { get set }

     /// A boolean that deletes tokens if they're not in use.
     var isValid: Bool { get }
}

/// An extension to provide a default initializer to tokens so that they can
/// be initialized manually in module code.
extension CorvusModelTokenAuthenticatable {

    /// Initializes a token.
    /// - Parameters:
    ///   - id: The unique identifier of the token.
    ///   - value: The `String` value of the token.
    ///   - userId: The id of the `User` the token belongs to.
    init(id: Self.IDValue? = nil, value: String, userId: User.IDValue) {
        self.init()
        self.value = value
        _$user.id = userId
     }
}

/// An extension to provide an authenticator for the token that can be
/// registered to the `Vapor` application, and field accessors for `value` and
/// `user`.
extension CorvusModelTokenAuthenticatable {

    /// Provides a `Vapor` authenticator defined below.
    /// - Parameter database: The database to authenticate.
    /// - Returns: A `CorvusModelTokenAuthenticator`.
    public static func authenticator(
        database: DatabaseID? = nil
    ) -> CorvusModelTokenAuthenticator<Self> {
        CorvusModelTokenAuthenticator<Self>(database: database)
    }

    /// Provides access to the `value` attribute.
    var _$value: Field<String> {
        guard let mirror = Mirror(reflecting: self).descendant("_value"),
            let token = mirror as? Field<String> else {
                fatalError("value property must be declared using @Field")
        }

        return token
    }

    /// Provides access to the `user` attribute.
    var _$user: Parent<User> {
        guard let mirror = Mirror(reflecting: self).descendant("_user"),
            let user = mirror as? Parent<User> else {
                fatalError("user property must be declared using @Parent")
        }

        return user
    }
}

/// Provides a `BearerAuthenticator` struct that defines how tokens are
/// authenticated.
public struct CorvusModelTokenAuthenticator<T: CorvusModelTokenAuthenticatable>:
BearerAuthenticator
{

    /// The token's user.
    public typealias User = T.User

    /// The database the token is saved in.
    public let database: DatabaseID?

    /// Authenticates a token.
    /// - Parameters:
    ///   - bearer: The bearer token passed in the request.
    ///   - request: The `Request` to be authenticated.
    /// - Returns: An empty `EventLoopFuture`.
    public func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
        let db = request.db(self.database)
        return T.query(on: db)
            .filter(\._$value == bearer.token)
            .first()
            .flatMap
        { token -> EventLoopFuture<Void> in
            guard let token = token else {
                return request.eventLoop.makeSucceededFuture(())
            }
            guard token.isValid else {
                return token.delete(on: db)
            }
            request.auth.login(token)
            return token._$user.get(on: db).map {
                request.auth.login($0)
            }
        }
    }
}
