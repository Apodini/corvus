import Vapor
import Fluent

/// A protocol that Corvus components conform to which provide some sort
/// operation (such as create, read) and which need to run queries on the
/// application's database.
public protocol QueryEndpoint: Endpoint {

    /// The subject of an operation's queries in its `.query()` method.
    associatedtype QuerySubject: CorvusModel

    /// The type returned after operating on a component's `.query()` in its
    /// `.handler()`.
    associatedtype Element: ResponseEncodable

    /// The HTTP method of the functionality of the component.
    var operationType: OperationType { get }

    /// A method to run database queries on a component's `QuerySubject`.
    func query(_ req: Request) throws -> QueryBuilder<QuerySubject>

    /// A method that runs logic on the results of the `.query()` and returns
    /// those results asynchronously in an  `EventLoopFuture`.
    func handler(_ req: Request) throws -> EventLoopFuture<Element>
}

/// An extension that provides a default empty database query for those
/// components that do not need custom `.query()` logic.
extension QueryEndpoint {

    /// A default implementation of `.query()` for components that do not
    /// require customized database queries.
    public func query(_ req: Request) throws -> QueryBuilder<QuerySubject> {
        QuerySubject.query(on: req.db)
    }
}
