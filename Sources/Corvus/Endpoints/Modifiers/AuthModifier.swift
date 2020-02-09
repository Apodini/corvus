import Vapor
import Fluent

/// A class that wraps a component which utilizes an `.auth()` modifier. That
/// allows Corvus to chain modifiers, as it gets treated as any other struct
/// conforming to `QueryEndpoint`.
public final class AuthModifier<
    Q: QueryEndpoint,
    E: EagerLoadable
>: QueryEndpoint
where E.EagerLoadValue: CorvusUser {

    /// The return type for the `.handler()` modifier.
    public typealias Element = Q.Element

    /// The return value of the `.handler()`, so the type being operated on in
    /// the current component.
    public typealias QuerySubject = Q.QuerySubject

    /// The `KeyPath` to the user property of the `QuerySubject` which is to be
    /// authenticated.
    public typealias UserKeyPath = KeyPath<Q.QuerySubject, E>

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
    public func query(_ req: Request) throws -> QueryBuilder<QuerySubject> {
        try queryEndpoint.query(req)
    }

    /// A method which checks if the `CorvusUser` supplied in the `Request` is
    /// equal to the user belonging to the particular `QuerySubject`.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An `EventLoopFuture` containing an eagerloaded value as
    /// defined by `Element`. If authentication fails or a user is not found,
    /// HTTP `.unauthorized` and `.notFound` are thrown respectively.
    public func handler(_ req: Request) throws -> EventLoopFuture<Element> {
        let users = try query(req)
            .with(userKeyPath)
            .all()
            .mapEach {
                $0[keyPath: self.userKeyPath].eagerLoaded
            }

        let authorized: EventLoopFuture<[Bool]> = users
            .mapEachThrowing { optionalUser throws -> Bool in

                guard let authorized = req.auth.get(CorvusUser.self) else {
                    throw Abort(.unauthorized)
                }

                guard let user = optionalUser else {
                    throw Abort(.notFound)
                }

                return authorized.validate(user)
            }

        return authorized.flatMap { authorized
            -> EventLoopFuture<AuthModifier<Q, E>.Element> in
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

    /// A method that registers the `.handler()` to the supplied
    /// `RoutesBuilder`, based on the `queryEndpoint`'s operation type.
    ///
    /// - Parameter routes: A `RoutesBuilder` containing all the information
    /// about the HTTP route leading to the current component.
    public func register(to routes: RoutesBuilder) {
        switch operationType {
        case .post:
            routes.post(use: handler)
        case .get:
            routes.get(use: handler)
        case .put:
            routes.put(use: handler)
        case .delete:
            routes.delete(use: handler)
        }
    }
}

/// An extension that adds the `.auth()` modifier to components conforming to
/// `AuthEndpoint`.
//@available(swift 5.2)
extension AuthEndpoint {

    /// A modifier used to make sure components only authorize requests where
    /// the supplied `CorvusUser` is actually related to the `QuerySubject`.
    ///
    /// - Parameter user: A `KeyPath` to the related user property.
    /// - Returns: An instance of a `AuthModifier` with the supplied `KeyPath`
    /// to the user.
    public func auth<E: EagerLoadable>(
        _ user: AuthModifier<Self, E>.UserKeyPath
    ) -> AuthModifier<Self, E> {
        AuthModifier(self, user: user)
    }
}
