import Vapor
import Fluent

/// A class that wraps a `Update` component which utilizes an `.auth()`
/// modifier. That allows Corvus to chain modifiers, as it gets treated as any
/// other struct conforming to `UpdateAuthModifier`. Requires an object `U` that
/// represents the user to authorize.
public final class UpdateAuthModifier<
    A: UpdateEndpoint,
    U: CorvusModelAuthenticatable>:
UpdateEndpoint, QueryEndpointModifier {

    /// The return type for the `.handler()` modifier.
    public typealias Element = A.Element

    /// The `KeyPath` to the user property of the `QuerySubject` which is to be
    /// authenticated.
    public typealias UserKeyPath = KeyPath<
        A.QuerySubject,
        A.QuerySubject.Parent<U>
    >

    /// The `ReadEndpoint` the `.auth()` modifier is attached to.
    public let modifiedEndpoint: A

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
        self.modifiedEndpoint = authEndpoint
        self.userKeyPath = user
    }

    /// A method which checks if the old value and the updated value both belong
    /// to the user making the request.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An `EventLoopFuture` containing an eagerloaded value as
    /// defined by `Element`. If authentication fails or a user is not found,
    /// HTTP `.unauthorized` and `.notFound` are thrown respectively.
    /// - Throws: An `Abort` error if an item is not found.
    public func handler(_ req: Request) throws -> EventLoopFuture<Element> {
        let updateContent = try req.content.decode(A.QuerySubject.self)
        let updateUser = updateContent[keyPath: self.userKeyPath]
        
        guard let authorized = req.auth.get(U.self) else {
            throw Abort(.unauthorized)
        }
        
        print(updateUser)
        
        let updateValid = authorized.id == updateUser.id
        
        let currentValid = try query(req)
            .with(userKeyPath)
            .first()
            .flatMapThrowing { item -> Bool in
                guard let unwrapped = item else {
                    throw Abort(.notFound)
                }
                
                guard let user = unwrapped[
                    keyPath: self.userKeyPath
                ].value else {
                    throw Abort(.notFound)
                }
                
                return user.id == authorized.id
            }
        
        return currentValid.flatMap { currentValid in
            guard currentValid && updateValid else {
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
/// `UpdateEndpoint`.
extension UpdateEndpoint {

    /// A modifier used to make sure components only authorize requests where
    /// the supplied user `U` is actually related to the `QuerySubject`.
    ///
    /// - Parameter user: A `KeyPath` to the related user property.
    /// - Returns: An instance of a `UpdateAuthModifier` with the supplied
    /// `KeyPath` to the user.
    public func auth<T: CorvusModelAuthenticatable>(
        _ user: UpdateAuthModifier<Self, T>.UserKeyPath
    ) -> UpdateAuthModifier<Self, T> {
        UpdateAuthModifier(self, user: user)
    }
}
