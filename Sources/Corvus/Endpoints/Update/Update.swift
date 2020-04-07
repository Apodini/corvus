import Vapor
import Fluent

/// A class that provides functionality to update objects of a generic type
/// `T` conforming to `CorvusModel` and identified by a route parameter.
public final class Update<T: CorvusModel>: AuthEndpoint {

    /// The return type of the `.handler()`.
    public typealias QuerySubject = T

    /// The ID of the item to be updated.
    let id: PathComponent

    /// The HTTP method for `Update` is PUT.
    public let operationType: OperationType = .put

    /// Initializes the component with a given path parameter.
    ///
    /// - Parameter id: A `PathComponent` which represents the ID of the item
    /// to be deleted.
    public init(_ id: PathComponent) {
        self.id = id
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
            parameter, as: QuerySubject.IDValue.self
        ) else {
            throw Abort(.badRequest)
        }
        return T.query(on: req.db).filter(\T._$id == itemId)
    }

    /// A method to update an item by an ID and new values supplied in the
    /// `Request`.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An `EventLoopFuture` containing the updated value of the
    /// object of type `QuerySubject`.
    /// - Throws: An `Abort` error if the item is not found.
    public func handler(_ req: Request) throws ->
        EventLoopFuture<QuerySubject>
    {
        let updatedItem = try req.content.decode(T.self)
        return try query(req)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { item in
                updatedItem.id = item.id
                return updatedItem.update(on: req.db).map { updatedItem }
            }
    }
}
