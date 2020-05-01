import Vapor
import Fluent

/// A class that provides functionality to delete objects completely of a
/// generic type `T` conforming to `CorvusModel` and identified by a route
/// parameter.
public final class Delete<T: CorvusModel>: AuthEndpoint {

    /// The return type of the `.handler()`.
    public typealias QuerySubject = T

    /// The return type of the `.query()`.
    public typealias Element = HTTPStatus

    /// The id of the object to be deleted.
    let id: PathComponent
    
    /// Indicates whether soft delete should be included or not.
    let useSoftDelete: Bool

    /// The HTTP operation type of the component.
    public let operationType: OperationType = .delete
    
    /// Initializes the component with a given path parameter.
    ///
    /// - Parameters:
    ///     - id: A `PathComponent` which represents the ID of the item.
    ///     - softDelete: Whether deletion should include soft deleted
    ///     items or not.
    public init(_ id: PathComponent, softDelete: Bool = false) {
        self.id = id
        self.useSoftDelete = softDelete
    }

    /// A method to find an item by an ID supplied in the `Request`.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: A `QueryBuilder`, which represents a `Fluent` query after
    /// having found the object with the supplied ID.
    /// - Throws: An `Abort` error if the item is not found.
    public func query(_ req: Request) throws -> QueryBuilder<QuerySubject> {
        let parameter = String(id.description.dropFirst())
        guard let itemId = req.parameters.get(
            parameter,
            as: QuerySubject.IDValue.self
        ) else {
            throw Abort(.badRequest)
        }
        
        if useSoftDelete {
            return T.query(on: req.db).filter(\T._$id == itemId)
        }
        
        return T.query(on: req.db).withDeleted().filter(\T._$id == itemId)
    }

    /// A method to delete an object found in the `.query()` from the database.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: A HTTPStatus of either `.ok`, when the object was
    /// successfully deleted, or `.notFound`, when the object was not found.
    /// - Throws: An `Abort` error if the item is not found.
    public func handler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try query(req)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap {
                self.useSoftDelete
                    ? $0.delete(on: req.db)
                    : $0.delete(force: true, on: req.db)
            }
            .map { .ok }
    }
}
