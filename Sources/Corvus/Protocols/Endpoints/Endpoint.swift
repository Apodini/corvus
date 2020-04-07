import Vapor

/// A protocol most Corvus components in a hierarchy conform to, so that they
/// may be treated as the same type interchangeably.
public protocol Endpoint {

    /// The content of an `Endpoint`, used for components which can harbor other
    /// components, e.g.`Group`.
    var content: Endpoint { get }

    /// A method needed to implement registration of an endpoint to the
    /// `Router` provided by Vapor, this handles the logic of making certain
    /// operations accessible on certain route paths.
    ///
    /// - Parameter routes: The `RoutesBuilder` containing HTTP route
    /// information up to this point.
    func register(to routes: RoutesBuilder)
}

/// An extension to provide a default empty content for components that can not
/// contain other components.
extension Endpoint {

    /// An empty default implementation for `content` for components that do not
    /// have it.
    public var content: Endpoint { EmptyEndpoint() }
}

/// An extension to provide a default empty registration for components that
/// do not need to be registered.
extension Endpoint {

    /// A default implementation of `.register()` for components that do not
    /// need special behaviour.
    ///
    /// - Parameter routes: The `RoutesBuilder` containing HTTP route
    /// information up to this point.
    public func register(to routes: RoutesBuilder) {
        content.register(to: routes)
    }
}

/// An extension to make an `Array` of `Endpoint` conform to `Endpoint` and thus
/// allowing Corvus to treat an `Array` like a single `Endpoint`.
extension Array: Endpoint where Element == Endpoint {

    /// An `Array` of `Endpoint` is registered by registering all of the
    /// `Array`'s elements.
    /// 
    /// - Parameter routes: The `RoutesBuilder` containing HTTP route
    /// information up to this point.
    public func register(to routes: RoutesBuilder) {
        forEach({ $0.register(to: routes) })
    }
}
