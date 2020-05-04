// swiftlint:disable line_length
import Vapor
import Fluent

/// A class that wraps a `Create` component which utilizes an `.auth()`
/// modifier. That allows Corvus to chain modifiers, as it gets treated as any
/// other struct conforming to `NestedCreateAuthModifier`. Requires an object
/// `U` that represents the user to authorize.
public final class NestedCreateAuthModifier<
    A: CreateEndpoint,
    I: CorvusModel,
    U: CorvusModelAuthenticatable>:
CreateEndpoint, QueryEndpointModifier {

    /// The return type for the `.handler()` modifier.
    public typealias Element = A.Element

    /// The `KeyPath` to the user property of the intermediate `I` which is to
    /// be authenticated.
    public typealias UserKeyPath = KeyPath<
        I,
        I.Parent<U>
    >
    
    /// The `KeyPath` to the intermediate `I` of the endpoint's `QuerySubject`.
    public typealias IntermediateKeyPath = KeyPath<
        A.QuerySubject,
        A.QuerySubject.Parent<I>
    >

    /// The `ReadEndpoint` the `.auth()` modifier is attached to.
    public let modifiedEndpoint: A

    /// The path to the property to authenticate for.
    public let userKeyPath: UserKeyPath
    
    /// The path to the intermediate.
    public let intermediateKeyPath: IntermediateKeyPath

    /// Initializes the modifier with its underlying `QueryEndpoint` and its
    /// `auth` path, which is the keypath to the property to run authentication
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
        self.modifiedEndpoint = authEndpoint
        self.intermediateKeyPath = intermediate
        self.userKeyPath = user
    }

    /// A method which checks if the user `U` supplied in the `Request` is
    /// equal to the user belonging to the particular `QuerySubject`.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An `EventLoopFuture` containing an eagerloaded value as
    /// defined by `Element`. If authentication fails or a user is not found,
    /// HTTP `.unauthorized` and `.notFound` are thrown respectively.
    /// - Throws: An `Abort` error if an item is not found.
    public func handler(_ req: Request) throws -> EventLoopFuture<Element> {
        let requestContent = try req.content.decode(A.QuerySubject.self)
        
        guard let intermediateId = requestContent[
              keyPath: self.intermediateKeyPath
        ].$id.value else {
            throw Abort(.notFound)
        }
        
        let authorized = I.query(on: req.db)
            .filter(\._$id == intermediateId)
            .with(userKeyPath)
            .first()
            .flatMapThrowing { optionalIntermediate -> Bool in
                guard let intermediate = optionalIntermediate else {
                    throw Abort(.notFound)
                }
                
                guard let user = intermediate[
                    keyPath: self.userKeyPath
                ].value else {
                    throw Abort(.notFound)
                }
                
                guard let authorized = req.auth.get(U.self) else {
                    throw Abort(.unauthorized)
                }
                
                return user.id == authorized.id

            }
        
        return authorized.flatMap { authorized in
            guard authorized else {
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
/// `CreateEndpoint`.
extension CreateEndpoint {

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
        _ intermediate: NestedCreateAuthModifier<Self, I, U>.IntermediateKeyPath,
        _ user: NestedCreateAuthModifier<Self, I, U>.UserKeyPath
    ) -> NestedCreateAuthModifier<Self, I, U> {
        NestedCreateAuthModifier(self, intermediate: intermediate, user: user)
    }
}
