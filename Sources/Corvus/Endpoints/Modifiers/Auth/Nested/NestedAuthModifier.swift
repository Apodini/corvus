import Vapor
import Fluent

/// A class that wraps a component which utilizes an `.auth()` modifier. Differs
/// from `AuthModifier` by authenticating on the user of an intermediate parent
/// `I` of `A.QuerySubject`. Requires an object `U` that represents the user to
/// authorize.
public class NestedAuthModifier<
    A: AuthEndpoint,
    I: CorvusModel,
    U: CorvusModelAuthenticatable>:
RestModifier<A>, AuthEndpoint {
    
    /// The `KeyPath` to the user property of the `QuerySubject` which is to be
    /// authenticated.
    public typealias UserKeyPath = KeyPath<
        I,
        I.Parent<U>
    >
    
    /// The `KeyPath` to the intermediate `I` of the endpoint's `QuerySubject`.
    public typealias IntermediateKeyPath = KeyPath<
        A.QuerySubject,
        A.QuerySubject.Parent<I>
    >
    
    /// The path to the property to authenticate for.
    public let userKeyPath: UserKeyPath
        
    /// The path to the intermediate.
    public let intermediateKeyPath: IntermediateKeyPath

    /// Initializes the modifier with its underlying `QueryEndpoint` and its
    /// `auth` path, which is the keypath to the property to run authorization
    /// for.
    ///
    /// - Parameters:
    ///     - queryEndpoint: The `QueryEndpoint` which the modifer is attached
    ///     to.
    ///     - intermediate: A `KeyPath` to the intermediate.
    ///     - user: A `KeyPath` which leads to the property to authenticate for.
    public init(
        _ authEndpoint: A,
        intermediate: IntermediateKeyPath,
        user: UserKeyPath
    ) {
        self.intermediateKeyPath = intermediate
        self.userKeyPath = user
        super.init(authEndpoint)
    }
    
    
    /// A method which checks if the user `U` supplied in the `Request` is
    /// equal to the user belonging to the particular `QuerySubject`.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An `EventLoopFuture` containing an eagerloaded value as
    /// defined by `Element`. If authorization fails or a user is not found,
    /// HTTP `.unauthorized` and `.notFound` are thrown respectively.
    /// - Throws: An `Abort` error if an item is not found.
    override public func handler(_ req: Request)
        throws -> EventLoopFuture<Element>
    {
        let users = try query(req)
            .with(intermediateKeyPath) {
                $0.with(userKeyPath)
            }.all()
            .mapEachThrowing { item -> U in
                guard let intermediate = item[
                    keyPath: self.intermediateKeyPath
                ].value else {
                    throw Abort(.notFound)
                }
                
                guard let user = intermediate[
                    keyPath: self.userKeyPath
                ].value else {
                    throw Abort(.notFound)
                }
                
                return user
            }

        let authorized: EventLoopFuture<[Bool]> = users
            .mapEachThrowing { user throws -> Bool in
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

/// An extension that adds a version of the  `.auth()` modifier to components
/// conforming to `AuthEndpoint` that allows defining an intermediate type `I`.
extension AuthEndpoint {

    /// A modifier used to make sure components only authorize requests where
    /// the supplied user `U` is actually related to the `QuerySubject`.
    ///
    /// - Parameters:
    ///     - intermediate: A `KeyPath` to the intermediate property.
    ///     - user: A `KeyPath` to the related user property from the
    ///     intermediate.
    /// - Returns: An instance of a `AuthModifier` with the supplied `KeyPath`
    /// to the user.
    public func auth<I: CorvusModel, U: CorvusModelAuthenticatable> (
        _ intermediate: NestedAuthModifier<Self, I, U>.IntermediateKeyPath,
        _ user: NestedAuthModifier<Self, I, U>.UserKeyPath
    ) -> NestedAuthModifier<Self, I, U> {
        NestedAuthModifier(self, intermediate: intermediate, user: user)
    }
}
