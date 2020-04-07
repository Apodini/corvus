import Vapor
import Fluent

/// A class that provides functionality to read objects of a generic type
/// `T` conforming to `CorvusModel` and identified by a route parameter.
public final class ReadOne<T: CorvusModel>: ReadEndpoint {

    /// The return type of the `.handler()`.
    public typealias QuerySubject = T
    
    /// The ID of the item to be read.
    let id: PathComponent

    /// Represents the type of `CorvusModel` to be read.
    public let target: ReadTarget<QuerySubject>
    
    /// Initializes the component with a given path parameter.
    ///
    /// - Parameter id: A `PathComponent` which represents the ID of the item
    /// - Parameter target: A `ReadTarget` which controls where to query the
    /// item from that is to be deleted.
    public init(
        _ id: PathComponent,
        _ target: ReadTarget<QuerySubject> = .existing) {
        self.id = id
        self.target = target
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
        
        return T.query(on: req.db).filter(\T._$id == itemId)
    }

    /// A method to return an object found in the `.query()` from the database,
    /// depending on the `target`.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: The found object.
    /// - Throws: An `Abort` error if the item is not found.
    public func handler(_ req: Request) throws ->
        EventLoopFuture<QuerySubject>
    {
        switch target.option {
        case .existing:
            return try query(req).first().unwrap(or: Abort(.notFound))
        case .all:
            return try query(req)
                .withDeleted()
                .first()
                .unwrap(or: Abort(.notFound))
        case .trashed(let deletedTimestamp):
            return try query(req)
                .withDeleted()
                .filter(
                    .path(deletedTimestamp.path, schema: T.schema),
                    .notEqual,
                    .null
                )
                .first()
                .unwrap(or: Abort(.notFound))
        }
    }
}
