import Vapor
import Fluent

/// A class that wraps a component which utilizes an `.auth()` modifier. That
/// allows Corvus to chain modifiers, as it gets treated as any other struct
/// conforming to `AuthEndpoint`. Requires an object `U` that represents the
/// user to authorize.
public class AuthModifier<
    A: AuthEndpoint,
    U: CorvusModelAuthenticatable>:
RestModifier<A>, AuthEndpoint {
    
    /// The `KeyPath` to the user property of the `QuerySubject` which is to be
    /// authenticated.
    public typealias UserKeyPath = KeyPath<
        QuerySubject,
        QuerySubject.Parent<U>
    >

    /// The path to the property to authenticate for.
    public let userKeyPath: UserKeyPath

    /// Initializes the modifier with its underlying `QueryEndpoint` and its
    /// `auth` path, which is the keypath to the property to run authentication
    /// for.
    ///
    /// - Parameters:
    ///     - queryEndpoint: The `QueryEndpoint` which the modifer is attached
    ///     to.
    ///     - user: A `KeyPath` which leads to the property to authenticate for.
    ///     - operationType: The HTTP method of the wrapped component.
    public init(_ authEndpoint: A, user: UserKeyPath) {
        self.userKeyPath = user
        super.init(authEndpoint)
    }

    /// A method which checks if the user `U` supplied in the `Request` is
    /// equal to the user belonging to the particular `QuerySubject`.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An `EventLoopFuture` containing an eagerloaded value as
    /// defined by `Element`. If authentication fails or a user is not found,
    /// HTTP `.unauthorized` and `.notFound` are thrown respectively.
    /// - Throws: An `Abort` error if an item is not found.
    override public func handler(_ req: Request)
        throws -> EventLoopFuture<Element>
    {
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

                guard let authorized = req.auth.get(U.self) else {
                    throw Abort(.unauthorized)
                }

                return authorized.id == user.id
            }

        return authorized.flatMap { authorized in
            guard authorized.allSatisfy({ $0 }) else {
                return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
            }

            do {
                return try self.modifiedEndpoint.handler(req)
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
    /// the supplied user `U` is actually related to the `QuerySubject`.
    ///
    /// - Parameter user: A `KeyPath` to the related user property.
    /// - Returns: An instance of a `AuthModifier` with the supplied `KeyPath`
    /// to the user.
    public func auth<U: CorvusModelAuthenticatable>(
        _ user: AuthModifier<Self, U>.UserKeyPath
    ) -> AuthModifier<Self, U> {
        AuthModifier(self, user: user)
    }
}
