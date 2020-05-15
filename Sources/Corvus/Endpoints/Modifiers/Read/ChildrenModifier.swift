import Vapor
import Fluent

/// A class that wraps a component which utilizes a `.children()` modifier. That
/// allows Corvus to chain modifiers, as it gets treated as any other struct
/// conforming to `ReadEndpoint`.
public final class ChildrenModifier<
    R: ReadEndpoint,
    M: CorvusModel>:
ReadEndpoint {

    /// The type of the value loaded with the `.children()` modifier.
    public typealias Element = [M]

    /// The return value of the `.handler()`, so the type being operated on in
    /// the current component.
    public typealias QuerySubject = M
    
    /// The type being operated on by the prior component in the modifier chain.
    public typealias ParentQuerySubject = R.QuerySubject

    /// The `KeyPath` to the related attribute of the `QuerySubject` that is to
    /// be loaded.
    public typealias ChildrenPath = KeyPath<
        ParentQuerySubject, ParentQuerySubject.Children<M>
    >

    /// The `KeyPath` passed to the `QuerySubject`.
    let childrenPath: ChildrenPath
    
    /// The instance of `Endpoint` the `RestEndpointModifier` is modifying.
    let modifiedEndpoint: R

    /// Initializes the modifier with its underlying `QueryEndpoint` and its
    /// `with` relation, which is the keypath to the child property.
    ///
    /// - Parameters:
    ///     - queryEndpoint: The `QueryEndpoint` which the modifer is attached
    ///     to.
    ///     - childrenPath: A `KeyPath` which leads to the child property.
    public init(_ readEndpoint: R, path: ChildrenPath) {
        self.modifiedEndpoint = readEndpoint
        self.childrenPath = path
    }

    /// Builds a query on the `queryEndpoint`'s query by attaching a with query
    /// modifier.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: A `QueryBuilder`, which represents a `Fluent` query after
    /// having attached a with modifier to the `queryEndpoint`'s query.
    /// - Throws: An `Abort` error if the item is not found.
    public func query(_ req: Request)
        throws -> QueryBuilder<ParentQuerySubject>
    {
        try modifiedEndpoint.query(req).with(childrenPath)
    }

    /// A method which eager loads objects related to the `QuerySubject` as
    /// defined by the `KeyPath`.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An `EventLoopFuture` containing an eagerloaded value as
    /// defined by `Element`.
    /// - Throws: An `Abort` error if the item is not found.
    public func handler(_ req: Request) throws -> EventLoopFuture<Element> {
        try query(req).first().flatMapThrowing { optionalItem in
            guard let item = optionalItem else {
                throw Abort(.notFound)
            }
            
            guard let eagerLoaded = item[
                keyPath: self.childrenPath
            ].value else {
                throw Abort(.notFound)
            }
            
            return eagerLoaded
        }
    }
}

/// An extension that adds a `.children()` modifier to `ReadEndpoints`.
extension ReadEndpoint {

    /// A modifier used to return items related to a component as defined by a
    /// given `KeyPath`.
    ///
    /// - Parameter with: A `KeyPath` to the related property.
    /// - Returns: An instance of a `ChildrenModifier` with the supplied
    /// `KeyPath` to the relationship.
    public func children<M: CorvusModel>(
        _ path: ChildrenModifier<Self, M>.ChildrenPath
    ) -> ChildrenModifier<Self, M> {
        ChildrenModifier(self, path: path)
    }
}
