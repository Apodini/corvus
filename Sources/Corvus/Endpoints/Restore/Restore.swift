import Vapor
import Fluent

/// A class that provides functionality to delete objects of a generic type
/// `T` conforming to `CorvusModel` and identified by a route parameter.
public final class Restore<T: CorvusModel>: Endpoint {

    /// The return type of the `.handler()`.
    public typealias QuerySubject = T

    /// The return type of the `.query()`.
    public typealias Element = HTTPStatus

    //TODO: Missing Documentation
    public typealias DeletedAtKeyPath = KeyPath<T, T.Timestamp>
    
   /// The ID of the item to be deleted.
    let id: PathComponent
    public let operationType: OperationType = .put

    //TODO: Missing Documentation
    public let deletedAtKey: DeletedAtKeyPath
    
    public init(_ id: PathComponent, deletedAtKey: DeletedAtKeyPath) {
        self.id = id
        self.deletedAtKey = deletedAtKey
    }

    /// A method to find an item by an ID supplied in the `Request`.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: A `QueryBuilder`, which represents a `Fluent` query after
    /// having found the object with the supplied ID.
    public func query(_ req: Request) throws -> QueryBuilder<QuerySubject> {
        let parameter = String(id.description.dropFirst())
        guard let itemId = req.parameters.get(parameter, as: QuerySubject.IDValue.self) else {
            throw Abort(.badRequest)
        }
        return T.query(on: req.db).withDeleted().filter(deletedAtKey != .null).filter(\T._$id == itemId)
    }

    /// A method to delete an object found in the `.query()` from the database.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: A HTTPStatus of either `.ok`, when the object was
    /// successfully deleted, or `.notFound`, when the object was not found.
    public func handler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try query(req)
            .first()
            .unwrap(or: Abort(.alreadyReported))
            .flatMap { $0.restore(on: req.db) }
            .map { .ok }
    }
    
    public func register(to routes: RoutesBuilder) {
        switch operationType {
        case .put: routes.put(use: handler)
//        case .patch: routes.patch(id, use: handler)
        default: assertionFailure("Not allowed")
        }
    }
}
