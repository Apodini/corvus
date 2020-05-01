import Vapor
import Fluent

/// A protocol that Corvus components conform to which provide some sort
/// operation (such as create, read) and which need to run queries on the
/// application's database.
public protocol QueryEndpoint: RestEndpoint {

    /// The subject of an operation's queries in its `.query()` method.
    associatedtype QuerySubject: CorvusModel

    /// A method to run database queries on a component's `QuerySubject`.
    ///
    /// - Parameter req: The incoming `Request`.
    /// - Throws: An error if something goes wrong.
    /// - Returns: A `QueryBuilder` for further querying after this `.query`.
    func query(_ req: Request) throws -> QueryBuilder<QuerySubject>
}

/// An extension that provides a default empty database query for those
/// components that do not need custom `.query()` logic.
extension QueryEndpoint {

    /// A default implementation of `.query()` for components that do not
    /// require customized database queries.
    /// 
    /// - Parameter req: The incoming `Request`.
    /// - Throws: An error if something goes wrong.
    /// - Returns: A `QueryBuilder` object for further querying.
    public func query(_ req: Request) throws -> QueryBuilder<QuerySubject> {
        QuerySubject.query(on: req.db)
    }
}
