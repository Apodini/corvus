import Vapor

/// An empty default value when no `Endpoint` value is needed.
public struct EmptyEndpoint: Endpoint {
    /// An empty default implementation of `.register()` to avoid endless loops when registering `EmptyEndpoint`s
    public func register(to routes: RoutesBuilder) { }
}
