import Vapor
import Fluent

/// A class that provides functionality to delete objects of a generic type
/// `T` conforming to `CorvusModel` and identified by a route parameter.
public final class Delete<T: CorvusModel>: AuthEndpoint {

    /// The return type of the `.handler()`.
    public typealias QuerySubject = T

    /// The return type of the `.query()`.
    public typealias Element = HTTPStatus

    /// The ID of the item to be deleted.
    let id: PathComponent
    public let operationType: OperationType = .delete

    public init(_ id: PathComponent) {
        self.id = id
    }

    /// A method to find an item by an ID supplied in the `Request`.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: A `QueryBuilder`, which represents a `Fluent` query after
    /// having found the object with the supplied ID.
    public func query(_ req: Request) throws -> QueryBuilder<QuerySubject> {
        let parameter = String(id.description.dropFirst())
        let itemId = req.parameters.get(parameter, as: Int.self)
        return T.query(on: req.db).filter(\T._$id == itemId)
    }

    /// A method to delete an object found in the `.query()` from the database.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: A HTTPStatus of either `.ok`, when the object was
    /// successfully deleted, or `.notFound`, when the object was not found.
    public func handler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try query(req)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .map { .ok }
    }

    /// A method that registers the `.handler()` to the supplied `RoutesBuilder`.
    ///
    /// - Parameter routes: A `RoutesBuilder` containing all the information
    /// about the HTTP route leading to the current component.
    public func register(to routes: RoutesBuilder) {
        routes.delete(use: handler)
    }
}
