import Vapor

/// A component capable of grouping multiple components conforming to `Endpoint`
/// under a HTTP route defined by `pathComponents`. This path is successively
/// within the tree hierarchy, meaning a `Group's` route path consists of its
/// `PathComponents` and those of the `Group's` above it in the hierarchy.
public struct Group: Endpoint {

    /// An array of `PathComponent` describing the path that the
    /// `BearerAuthGroup` extends.
    let pathComponents: [PathComponent]

    /// The content of the `BasicAuthGroup`, which can be any kind of Corvus
    /// component.
    public var content: Endpoint

    /// Creates a `Group` from a path and a builder function passed as
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
        self.content = content()
    }

    /// Creates a `Group` from a path and a builder function passed as
    /// a closure.
    ///
    /// - Parameters:
    ///     - pathComponents: One or more objects describing the route.
    ///     - content: An `EndpointBuilder`, which is a function builder that
    ///     takes in multiple `Endpoints` and returns them as a single
    ///     `Endpoint`.
    public init(
        _ pathComponents: [PathComponent],
        @EndpointBuilder content: () -> Endpoint
    ) {
        self.pathComponents = pathComponents
        self.content = content()
    }

    /// A method that registers the `content` of the `Group` to the
    /// supplied `RoutesBuilder`.
    ///
    /// - Parameter routes: A `RoutesBuilder` containing all the information
    /// about the HTTP route leading to the current component.
    public func register(to routes: RoutesBuilder) {
        let groupedRoutesBuilder: RoutesBuilder = pathComponents.reduce(
            routes,
            { $0.grouped($1) }
        )
        content.register(to: groupedRoutesBuilder)
    }
}
