import Vapor
import Fluent

/// A class that contains custom functionality passed in by the implementor for
/// a generic type `T` conforming to `CorvusModel` grouped under a given path.
public final class Custom<T: CorvusModel>: QueryEndpoint {

    /// The return value of the `.handler()`.
    public typealias Element = T

    /// The return value of the `query()`.
    public typealias QuerySubject = T

    /// The path to the component, can be used for route parameters.
    let path: PathComponent

    /// The HTTP method of the `Custom` operation.
    public let operationType: OperationType

    /// The custom handler passed in by the implementor.
    var customHandler: (Request) throws -> EventLoopFuture<QuerySubject>

    /// Initializes the component with path information, operation type of its
    /// functionality and a custom handler function passed in as a closure.
    ///
    /// - Parameters:
    ///     - pathComponents: One or more objects describing the route.
    ///     - operationType: The type of HTTP method the handler is used for.
    ///     - customHandler: A closure that implements the functionality for the
    ///     `Custom` component.
    public init(
        path: PathComponent,
        type operationType: OperationType,
        _ customHandler: @escaping (Request) throws -> EventLoopFuture<Element>
    ) {
        self.path = path
        self.operationType = operationType
        self.customHandler = customHandler
    }

    /// Not used, necessary for protocol conformance to `QueryEndpoint`.
    public func handler(_ req: Request) throws -> EventLoopFuture<Element> {
        try query(req).first().unwrap(or: Abort(.notFound))
    }

    /// A method that registers the `.handler()` to the supplied
    /// `RoutesBuilder` based on its `operationType`.
    ///
    /// - Parameter routes: A `RoutesBuilder` containing all the information
    /// about the HTTP route leading to the current component.
    public func register(to routes: RoutesBuilder) {
        switch operationType {
        case .post:
            routes.post(path, use: customHandler)
        case .get:
            routes.get(path, use: customHandler)
        case .put:
            routes.put(path, use: customHandler)
        case .delete:
            routes.delete(path, use: customHandler)
        case .patch:
            fatalError("Not implemented yet.")
        }
    }
}
