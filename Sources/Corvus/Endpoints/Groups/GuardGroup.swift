import Vapor

/// A component capable of grouping multiple components conforming to `Endpoint`
/// under a HTTP route defined by `pathComponents`. This path is successively
/// within the tree hierarchy, meaning a `GuardGroup's` route path consists of
/// its `PathComponents` and those of the `GuardGroup's`
/// above it in the hierarchy.
/// Additionally this group evaluates the authorization of incoming requests
/// using `Guard`s.
public struct GuardGroup: Endpoint {

    /// An array of `PathComponent` describing the path that the
    /// `GuardGroup` extends.
    let pathComponents: [PathComponent]

    /// An array of `Guard` that this `GuardGroup` utilizes to evaluates the
    /// authorization status of an incoming request.
    let guards: [Guard]
    
    /// The content of the `GuardGroup`, which can be any kind of Corvus
    /// component.
    public var content: Endpoint

    /// Creates a `GuardGroup` from a path, a `Guard`
    /// and a builder function passed as a closure.
    ///
    /// - Parameters:
    ///     - pathComponents: One or more objects describing the route.
    ///     - guard: The `Guard` used by this `GuardGroup`.
    ///     - content: An `EndpointBuilder`, which is a function builder that
    ///     takes in multiple `Endpoints` and returns them as a single
    ///     `Endpoint`.
    public init(
        _ pathComponents: PathComponent...,
        guard: Guard,
        @EndpointBuilder content: () -> Endpoint
    ) {
        self.pathComponents = pathComponents
        self.guards = [`guard`]
        self.content = content()
    }
    
    /// Creates a `GuardGroup` from a path, multiple `Guard`
    /// and a builder function passed as a closure.
    ///
    /// - Parameters:
    ///     - pathComponents: One object describing the route.
    ///     - guards: The `Guard`s used by this `GuardGroup`.
    ///     - content: An `EndpointBuilder`, which is a function builder that
    ///     takes in multiple `Endpoints` and returns them as a single
    ///     `Endpoint`.
    public init(
        _ pathComponent: PathComponent,
        guards: Guard...,
        @EndpointBuilder content: () -> Endpoint
    ) {
        self.pathComponents = [pathComponent]
        self.guards = guards
        self.content = content()
    }
    
    /// Creates a `GuardGroup` from a path, an array of `Guard`
    /// and a builder function passed as a closure.
    ///
    /// - Parameters:
    ///     - pathComponents: One or more objects describing the route.
    ///     - guards: The `Guard`s used by this `GuardGroup`.
    ///     - content: An `EndpointBuilder`, which is a function builder that
    ///     takes in multiple `Endpoints` and returns them as a single
    ///     `Endpoint`.
    public init(
        _ pathComponents: PathComponent...,
        guards: [Guard],
        @EndpointBuilder content: () -> Endpoint
    ) {
        self.pathComponents = pathComponents
        self.guards = guards
        self.content = content()
    }
    
    /// A method that registers the `content` of the `Group` to the
    /// supplied `RoutesBuilder`.
    ///
    /// - Parameter routes: A `RoutesBuilder` containing all the information
    /// about the HTTP route leading to the current component.
    public func register(to routes: RoutesBuilder) {
        let pathRoutesBuilder: RoutesBuilder = pathComponents.reduce(
            routes,
            { $0.grouped($1) }
        )

        let guardRoutesBuilder: RoutesBuilder = guards.reduce(
            pathRoutesBuilder,
            { $0.grouped($1) }
        )
        
        content.register(to: guardRoutesBuilder)
    }
}
