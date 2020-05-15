import Vapor
import Fluent

/// A class that wraps a `RestEndpoint` with additional functionalty.
/// This allows Corvus to chain modifiers, as it gets treated as any other
/// struct conforming to `RestEndpoint`.
public class RestModifier<R: RestEndpoint>: RestEndpoint {
        
    /// The return value of the `.query()`, so the type being operated on in
    /// the current component.
    public typealias QuerySubject = R.QuerySubject
    
    /// The return type for the `.handler()` modifier.
    public typealias Element = R.Element
    
    /// The instance of `Endpoint` the `RestEndpointModifier` is modifying.
    let modifiedEndpoint: R
    
    /// The HTTP method of the functionality of the component.
    public let operationType: OperationType

    /// An array of `PathComponent` describing the path that the
    /// `TypedEndpoint` extends.
    public let pathComponents: [PathComponent]
    
    /// Initializes the modifier with its underlying `RestEndpoint` and its
     /// `with` relation, which is the keypath to the related property.
     ///
     /// - Parameters:
     ///     - queryEndpoint: The `QueryEndpoint` which the modifer is attached
     ///     to.
     ///     - with: A `KeyPath` which leads to the desired property.
    init(_ restEndpoint: R) {
        self.modifiedEndpoint = restEndpoint
        self.operationType = modifiedEndpoint.operationType
        self.pathComponents = modifiedEndpoint.pathComponents
    }
    
    /// A default implementation of `.query()` for components that do not
    /// require customized database queries.
    ///
    /// - Parameter req: The incoming `Request`.
    /// - Throws: An error if something goes wrong.
    /// - Returns: A `QueryBuilder` object for further querying.
    public func query(_ req: Request) throws -> QueryBuilder<R.QuerySubject> {
        try modifiedEndpoint.query(req)
    }
    
    public func handler(_ req: Request) throws -> EventLoopFuture<Element> {
        try modifiedEndpoint.handler(req)
    }
}
