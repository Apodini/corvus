import Vapor

/// A component that is used at the root of each API and can get registered
/// to a `Vapor` `Application` by conforming to `RouteCollection`. It also
/// conforms to `Endpoint` to remain composable itself.
public protocol RestApi: RouteCollection, Endpoint {}

/// An extension providing a default implementation for the `RouteCollection`'s
/// `.boot()` method, recursively invoking registration for all of its
/// `content`.
extension RestApi {

    /// A default implementation for `boot` that recurses down the API's
    /// hierarchy.
    ///
    /// - Parameter routes: The `RoutesBuilder` containing HTTP route
    /// information up to this point.
    /// - Throws: An error if registration fails.
    public func boot(routes: RoutesBuilder) throws {
        content.register(to: routes)
    }
}

/// A convenience wrapper around `RestApi`.
///
/// Wraps `RestApi` by using a `Group` component
/// to reduce indendation when creating a Api.
public final class Api: RestApi {

    /// The content of an `Endpoint`, used for components which can harbor other
    /// components, e.g.`Group`.
    public let content: Endpoint

    /// An array of `PathComponent` describing the path that the
    /// `Api` extends.
    public let pathComponents: [PathComponent]
    
    /// Creates a `Api` from a path and a builder function passed as
    /// a closure.
    ///
    /// - Parameters:
    ///     - pathComponents: One or more objects describing the route.
    ///     - content: An `EndpointBuilder`, which is a function builder that
    ///     takes in multiple `Endpoints` and returns them as a single
    ///     `Endpoint`.
    public init(
        _ pathComponents: PathComponent...,
        @EndpointBuilder content: () -> Endpoint
    ) {
        self.pathComponents = pathComponents
        self.content = Group(pathComponents) { content() }
    }
}
