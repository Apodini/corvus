import Vapor
import Fluent

/// A class that wraps a component which utilizes an `.auth()` modifier. That
/// allows Corvus to chain modifiers, as it gets treated as any other struct
/// conforming to `AuthEndpoint`. Requires an object `T` that represents the
/// user to authorize.
public final class AuthModifier<Q: AuthEndpoint, T: CorvusModelUser>:
AuthEndpoint {

    /// The return type for the `.handler()` modifier.
    public typealias Element = Q.Element

    /// The return value of the `.query()`, so the type being operated on in
    /// the current component.
    public typealias QuerySubject = Q.QuerySubject

    /// The `KeyPath` to the user property of the `QuerySubject` which is to be
    /// authenticated.
    public typealias UserKeyPath = KeyPath<
        Q.QuerySubject,
        Q.QuerySubject.Parent<T>
    >

    /// The `ReadEndpoint` the `.auth()` modifier is attached to.
    public let queryEndpoint: Q

    /// The path to the property to authenticate for.
    public let userKeyPath: UserKeyPath

    /// The HTTP method of the wrapped method.
    public let operationType: OperationType

    /// Initializes the modifier with its underlying `QueryEndpoint` and its
    /// `auth` path, which is the keypath to the property to run authentication
    /// for.
    ///
    /// - Parameters:
    ///     - queryEndpoint: The `QueryEndpoint` which the modifer is attached
    ///     to.
    ///     - user: A `KeyPath` which leads to the property to authenticate for.
    ///     - operationType: The HTTP method of the wrapped component.
    public init(_ queryEndpoint: Q, user: UserKeyPath) {
        self.queryEndpoint = queryEndpoint
        self.userKeyPath = user
        self.operationType = queryEndpoint.operationType
    }

    /// Returns the `queryEndpoint`'s query.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: A `QueryBuilder`, which represents a `Fluent` query defined
    /// by the `queryEndpoint`.
    /// - Throws: An `Abort` error if the item is not found.
    public func query(_ req: Request) throws -> QueryBuilder<QuerySubject> {
        try queryEndpoint.query(req)
    }

    /// A method which checks if the user `T` supplied in the `Request` is
    /// equal to the user belonging to the particular `QuerySubject`.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An `EventLoopFuture` containing an eagerloaded value as
    /// defined by `Element`. If authentication fails or a user is not found,
    /// HTTP `.unauthorized` and `.notFound` are thrown respectively.
    /// - Throws: An `Abort` error if an item is not found.
    public func handler(_ req: Request) throws -> EventLoopFuture<Element> {
        let users = try query(req)
            .with(userKeyPath)
            .all()
            .mapEach {
                $0[keyPath: self.userKeyPath].value
            }

        let authorized: EventLoopFuture<[Bool]> = users
            .mapEachThrowing { optionalUser throws -> Bool in
                guard let user = optionalUser else {
                    throw Abort(.notFound)
                }

                guard let authorized = req.auth.get(T.self) else {
                    throw Abort(.unauthorized)
                }

                return authorized.id == user.id
            }

        return authorized.flatMap { authorized in
            guard authorized.allSatisfy({ $0 }) else {
                return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
            }

            do {
                return try self.queryEndpoint.handler(req)
            } catch {
                return req.eventLoop.makeFailedFuture(error)
            }
        }
    }
}

/// An extension that adds the `.auth()` modifier to components conforming to
/// `AuthEndpoint`.
extension AuthEndpoint {

    /// A modifier used to make sure components only authorize requests where
    /// the supplied user `T` is actually related to the `QuerySubject`.
    ///
    /// - Parameter user: A `KeyPath` to the related user property.
    /// - Returns: An instance of a `AuthModifier` with the supplied `KeyPath`
    /// to the user.
    public func auth<T: CorvusModelUser>(
        _ user: AuthModifier<Self, T>.UserKeyPath
    ) -> AuthModifier<Self, T> {
        AuthModifier(self, user: user)
    }
}
