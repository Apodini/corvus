import Vapor
import Fluent

/// A special type of `Group` that protects its `content` with basic
/// authentication for a generic `ModelUser`.
public struct BasicAuthGroup<T: CorvusModelUser>: Endpoint {

    /// An array of `PathComponent` describing the path that the
    /// `BasicAuthGroup` extends.
    let pathComponents: [PathComponent]

    /// The content of the `BasicAuthGroup`, which can be any kind of Corvus
    /// component.
    public var content: Endpoint

    /// Creates a `BasicAuthGroup` from a path and a builder function passed as
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


    /// A method that registers the `content` of the `BasicAuthGroup` to the
    /// supplied `RoutesBuilder`. It also registers basic authentication
    /// middleware using `T` conforming to `ModelUser`.
    ///
    /// - Parameter routes: A `RoutesBuilder` containing all the information
    /// about the HTTP route leading to the current component.
    public func register(to routes: RoutesBuilder) {
        let groupedRoutesBuilder: RoutesBuilder = pathComponents.reduce(
            routes,
            { $0.grouped($1) }
        )

        let guardedRoutesBuilder = groupedRoutesBuilder.grouped([
            T.guardMiddleware(),
            T.authenticator().middleware()
        ])
        
        content.register(to: guardedRoutesBuilder)
    }
}
