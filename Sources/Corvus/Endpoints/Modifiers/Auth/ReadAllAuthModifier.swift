import Vapor
import Fluent

/// A class that wraps a component which utilizes an `.auth()` modifier. Differs
/// from `AuthModifier` by authenticating on the user of an intermediate parent
/// `I` of `A.QuerySubject`. Requires an object `T` that represents the user to
/// authorize.
public final class ReadAllAuthModifier<
    A: AuthEndpoint,
    I: CorvusModel,
    T: CorvusModelAuthenticatable>:
AuthEndpoint, RestEndpointModifier {

    /// The return value of the `.query()`, so the type being operated on in
    /// the current component.
    public typealias QuerySubject = A.QuerySubject

    /// The `KeyPath` to the user property of the intermediate `I` which is to
    /// be authenticated.
    public typealias UserKeyPath = KeyPath<
        I,
        I.Parent<T>
    >
    
    /// The `KeyPath` to the intermediate `I` of the endpoint's `QuerySubject`.
    public typealias IntermediateKeyPath = KeyPath<
        A.QuerySubject,
        A.QuerySubject.Parent<I>
    >

    /// The `AuthEndpoint` the `.auth()` modifier is attached to.
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
    ///     - operationType: The HTTP method of the wrapped component.
    public init(
        _ authEndpoint: A,
        intermediate: IntermediateKeyPath,
        user: UserKeyPath
    ) {
        self.modifiedEndpoint = authEndpoint
        self.intermediateKeyPath = intermediate
        self.userKeyPath = user
    }

    /// Returns the `queryEndpoint`'s query.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: A `QueryBuilder`, which represents a `Fluent` query defined
    /// by the `queryEndpoint`.
    /// - Throws: An `Abort` error if the item is not found.
    public func query(_ req: Request) throws -> QueryBuilder<QuerySubject> {
        try modifiedEndpoint.query(req)
    }

    /// A method which checks if the user `T` supplied in the `Request` is
    /// equal to the user belonging to the particular `QuerySubject`.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An `EventLoopFuture` containing an eagerloaded value as
    /// defined by `Element`. If authentication fails or a user is not found,
    /// HTTP `.unauthorized` and `.notFound` are thrown respectively.
    /// - Throws: An `Abort` error if an item is not found.
    public func handler(_ req: Request) throws ->
        EventLoopFuture<[QuerySubject]>
    {
        try query(req)
            .with(intermediateKeyPath) {
                $0.with(userKeyPath)
            }.all()
            .flatMapEachCompactThrowing { item -> QuerySubject? in
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
                
                guard let authorized = req.auth.get(T.self) else {
                    throw Abort(.unauthorized)
                }
                
                if authorized.id == user.id {
                    return item
                } else {
                    return nil
                }
        }
    }
}

/// An extension that adds a version of the  `.auth()` modifier to components
/// conforming to `AuthEndpoint` that allows defining an intermediate type `I`.
extension ReadAll {

    /// A modifier used to make sure components only authorize requests where
    /// the supplied user `T` is actually related to the `QuerySubject`.
    ///
    /// - Parameter intermediate: A `KeyPath` to the intermediate property.
    /// - Parameter user: A `KeyPath` to the related user property from the
    /// intermediate.
    /// - Returns: An instance of a `AuthModifier` with the supplied `KeyPath`
    /// to the user.
    public func auth<I: CorvusModel, T: CorvusModelAuthenticatable> (
        _ intermediate: ReadAllAuthModifier<ReadAll, I, T>.IntermediateKeyPath,
        _ user: ReadAllAuthModifier<ReadAll, I, T>.UserKeyPath
    ) -> ReadAllAuthModifier<ReadAll, I, T> {
        ReadAllAuthModifier(self, intermediate: intermediate, user: user)
    }
}
