import Vapor

/// A class that provides functionality to create objects of a generic type
/// `T` conforming to `CorvusModel`.
public final class Create<T: CorvusModel>: QueryEndpoint {

    /// The return type of the `.handler()`.
    public typealias QuerySubject = T

    public let operationType: OperationType = .post

    public init() {}

    /// A method that saves objects from a `Request` to the database.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An `EventLoopFuture` containing the saved object.
    public func handler(_ req: Request)
        throws -> EventLoopFuture<QuerySubject> {
        let requestContent = try req.content.decode(QuerySubject.self)
        return requestContent.save(on: req.db).map { requestContent }
    }
}
