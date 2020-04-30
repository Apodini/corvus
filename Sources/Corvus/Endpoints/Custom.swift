import Vapor
import Fluent

/// A class that contains custom functionality passed in by the implementor for
/// a generic type `T conforming to `ResponseEncodable` grouped under a given
/// path.
public final class Custom<R: CorvusModel>: QueryEndpoint {
    
    /// The return value of the `.handler()`.
    public typealias Element = R
    
    /// The type the Component operates on.
    public typealias QuerySubject = R

    /// The path to the component, can be used for route parameters.
    public let pathComponents: [PathComponent]

    /// The HTTP method of the `Custom` operation.
    public let operationType: OperationType

    /// The custom handler passed in by the implementor.
    var customHandler: (Request) throws -> EventLoopFuture<Element>

    /// Initializes the component with path information, operation type of its
    /// functionality and a custom handler function passed in as a closure.
    ///
    /// - Parameters:
    ///     - pathComponents: One or more objects describing the route.
    ///     - operationType: The type of HTTP method the handler is used for.
    ///     - customHandler: A closure that implements the functionality for the
    ///     `Custom` component.
    public init(
        pathComponents: PathComponent...,
        type operationType: OperationType,
        _ customHandler: @escaping (Request) throws -> EventLoopFuture<Element>
    ) {
        self.pathComponents = pathComponents
        self.operationType = operationType
        self.customHandler = customHandler
    }

    /// A method to return an element of type `T` return by the custom handler.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An element of type `T`.
    /// - Throws: An `Abort` error if something goes wrong.
    public func handler(_ req: Request) throws -> EventLoopFuture<Element> {
        try customHandler(req)
    }
}
