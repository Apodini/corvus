import Vapor

/// A class that provides functionality to create objects of a generic type
/// `T` conforming to `CorvusModel`.
public final class Create<T: CorvusModel>: CreateAuthEndpoint {

    /// The return type of the `.handler()`.
    public typealias QuerySubject = T

    /// The HTTP operation type of the component.
    public let operationType: OperationType = .post

    /// An initializer for creation without arguments.
    public init() {}

    /// A method that saves objects from a `Request` to the database.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An `EventLoopFuture` containing the saved object.
    /// - Throws: An `Abort` error if something goes wrong.
    public func handler(_ req: Request) throws ->
        EventLoopFuture<QuerySubject>
    {
        let requestContent = try req.content.decode(QuerySubject.self)
        return requestContent.save(on: req.db).map { requestContent }
    }
}
