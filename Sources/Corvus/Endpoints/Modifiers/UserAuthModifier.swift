import Vapor
import Fluent

/// A class that wraps a component which utilizes an `.userAuth()` modifier.
/// That allows Corvus to chain modifiers, as it gets treated as any other
/// struct conforming to `AuthEndpoint`.
public final class UserAuthModifier<Q: AuthEndpoint>: AuthEndpoint
where Q.QuerySubject: CorvusModelAuthenticatable {

    /// The return type for the `.handler()` modifier.
    public typealias Element = Q.Element

    /// The return value of the `.query()`, so the type being operated on in
    /// the current component.
    public typealias QuerySubject = Q.QuerySubject

    /// The `AuthEndpoint` the `.userAuth()` modifier is attached to.
    public let queryEndpoint: Q

    /// The HTTP method of the wrapped method.
    public let operationType: OperationType

    /// Initializes the modifier with its underlying `QueryEndpoint`.
    ///
    /// - Parameters:
    ///     - queryEndpoint: The `QueryEndpoint` which the modifer is attached
    ///     to.
    ///     - operationType: The HTTP method of the wrapped component.
    public init(_ queryEndpoint: Q) {
        self.queryEndpoint = queryEndpoint
        self.operationType = queryEndpoint.operationType
    }

    /// Returns the `queryEndpoint`'s query.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: A `QueryBuilder`, which represents a `Fluent` query defined
    /// by the `queryEndpoint`.
    /// - Throws: An `Abort` error if an item is not found.
    public func query(_ req: Request) throws -> QueryBuilder<QuerySubject> {
        try queryEndpoint.query(req)
    }

    /// A method which checks if the user supplied in the `Request` is
    /// equal to the user belonging to the particular `QuerySubject`.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An `EventLoopFuture` containing an eagerloaded value as
    /// defined by `Element`. If authentication fails or a user is not found,
    /// HTTP `.unauthorized` and `.notFound` are thrown respectively.
    /// - Throws: An `Abort` error if an item is not found.
    public func handler(_ req: Request) throws -> EventLoopFuture<Element> {
        let users = try query(req).all()
             
        let authorized: EventLoopFuture<[Bool]> = users
            .mapEachThrowing { user throws -> Bool in

                guard let authorized = req.auth.get(QuerySubject.self) else {
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

/// An extension that adds the `.userAuth()` modifier to components conforming
/// to `AuthEndpoint`.
extension AuthEndpoint where Self.QuerySubject: CorvusModelAuthenticatable {

    /// A modifier used to make sure components only authorize requests where
    /// the supplied `CorvusUser` is actually related to the `QuerySubject`.
    ///
    /// - Parameter user: A `KeyPath` to the related user property.
    /// - Returns: An instance of a `AuthModifier` with the supplied `KeyPath`
    /// to the user.
    func userAuth() -> UserAuthModifier<Self> {
        UserAuthModifier(self)
    }
}
