import Vapor

/// A class that wraps a `RestEndpoint` with additional functionalty.
/// This allows Corvus to chain modifiers, as it gets treated as any other
/// struct conforming to `RestEndpoint`.
protocol RestEndpointModfier: RestEndpoint {
    /// The type of `RestEndpoint` the `RestEndpointModfier` is modifying.
    associatedtype Endpoint: RestEndpoint
    
    /// The instance of `Endpoint` the `RestEndpointModfier` is modifying.
    var modifiedEndpoint: Endpoint { get }
}

extension RestEndpointModfier {
    /// The HTTP method of the functionality of the component.
    public var operationType: OperationType {
        modifiedEndpoint.operationType
    }
    
    /// An array of PathComponent describing the path that the TypedEndpoint extends.
    public var pathComponents: [PathComponent] {
        modifiedEndpoint.pathComponents
    }
}
