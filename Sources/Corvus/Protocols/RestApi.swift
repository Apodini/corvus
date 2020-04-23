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
    public let content: Endpoint
    let pathComponents: [PathComponent]
    
    public init(
        _ pathComponents: PathComponent...,
        @EndpointBuilder content: () -> Endpoint
    ) {
        self.pathComponents = pathComponents
        self.content = Group(pathComponents) { content() }
    }
}
