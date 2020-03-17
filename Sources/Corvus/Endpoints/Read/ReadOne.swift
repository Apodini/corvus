import Vapor
import Fluent

/// A class that provides functionality to read objects of a generic type
/// `T` conforming to `CorvusModel` and identified by a route parameter.
public final class ReadOne<T: CorvusModel>: ReadEndpoint {

    /// The return type of the `.handler()`.
    public typealias QuerySubject = T

    /// The ID of the item to be deleted.
    let id: PathComponent

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
    public func query(_ req: Request) throws -> QueryBuilder<QuerySubject> {
        let parameter = String(id.description.dropFirst())
        guard let itemId = req.parameters.get(parameter, as: QuerySubject.IDValue.self) else {
            throw Abort(.badRequest)
        }
        return T.query(on: req.db).filter(\T._$id == itemId)
    }

    /// A method to return an object found in the `.query()` from the database.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: The found object.
    public func handler(_ req: Request) throws -> EventLoopFuture<QuerySubject> {
        try query(req).first().unwrap(or: Abort(.notFound))
    }

    /// A method that registers the `.handler()` to the supplied `RoutesBuilder`.
    ///
    /// - Parameter routes: A `RoutesBuilder` containing all the information
    /// about the HTTP route leading to the current component.
    public func register(to routes: RoutesBuilder) {
        routes.get(use: handler)
    }
}
