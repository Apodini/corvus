import Vapor

/// A class that wraps a `RestEndpoint` with additional functionalty.
/// This allows Corvus to chain modifiers, as it gets treated as any other
/// struct conforming to `RestEndpoint`.
protocol RestEndpointModifier: RestEndpoint {
    /// The type of `RestEndpoint` the `RestEndpointModifier` is modifying.
    associatedtype Endpoint: RestEndpoint
    
    /// The instance of `Endpoint` the `RestEndpointModifier` is modifying.
    var modifiedEndpoint: Endpoint { get }
}

extension RestEndpointModifier {
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
