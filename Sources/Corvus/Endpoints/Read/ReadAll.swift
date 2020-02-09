import Vapor
import Fluent

/// A class that provides functionality to read all objects of a generic type
/// `T` conforming to `CorvusModel`.
public final class ReadAll<T: CorvusModel>: ReadEndpoint {

    /// The return type of the `.handler()`.
    public typealias QuerySubject = T

    /// Makes the initializer of the component public.
    public init() {}

    /// A method to return all objects of the type `QuerySubject` from the
    /// database.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An array of `QuerySubjects`.
    public func handler(_ req: Request) throws -> EventLoopFuture<[QuerySubject]> {
        try query(req).all()
    }

    /// A method that registers the `.handler()` to the supplied `RoutesBuilder`.
    ///
    /// - Parameter routes: A `RoutesBuilder` containing all the information
    /// about the HTTP route leading to the current component.
    public func register(to routes: RoutesBuilder) {
        routes.get(use: handler)
    }
}
