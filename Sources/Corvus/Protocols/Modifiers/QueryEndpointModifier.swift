import Vapor
import Fluent

/// A class that wraps a `RestEndpoint` with additional functionalty.
/// This allows Corvus to chain modifiers, as it gets treated as any other
/// struct conforming to `RestEndpoint`.
protocol QueryEndpointModifier: QueryEndpoint {
    
    /// The type of `RestEndpoint` the `RestEndpointModifier` is modifying.
    associatedtype ParentEndpoint: QueryEndpoint
    
    /// The instance of `Endpoint` the `RestEndpointModifier` is modifying.
    var modifiedEndpoint: ParentEndpoint { get }
}

extension QueryEndpointModifier {
    /// The HTTP method of the functionality of the component.
    public var operationType: OperationType {
        modifiedEndpoint.operationType
    }
    
    /// An array of PathComponent describing the path that the
    /// TypedEndpoint extends.
    public var pathComponents: [PathComponent] {
        modifiedEndpoint.pathComponents
    }
}

/// An extension that provides a default empty database query for those
/// components that do not need custom `.query()` logic.
extension QueryEndpointModifier {

    /// A default implementation of `.query()` for components that do not
    /// require customized database queries.
    ///
    /// - Parameter req: The incoming `Request`.
    /// - Throws: An error if something goes wrong.
    /// - Returns: A `QueryBuilder` object for further querying.
    public func query(_ req: Request)
        throws -> QueryBuilder<ParentEndpoint.QuerySubject>
    {
        try modifiedEndpoint.query(req)
    }
}

