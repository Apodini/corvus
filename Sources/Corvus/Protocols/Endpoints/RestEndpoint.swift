import Fluent
import Vapor

/// Defines a generic type for `RESTful` endpoints.
public protocol RestEndpoint: Endpoint {

    /// The type returned after from the `.handler()`.
    associatedtype Element: ResponseEncodable
    
    /// The subject of an operation's queries in its `.query()` method.
    associatedtype QuerySubject: CorvusModel

    /// The HTTP method of the functionality of the component.
    var operationType: OperationType { get }

    /// An array of `PathComponent` describing the path that the
    /// `TypedEndpoint` extends.
    var pathComponents: [PathComponent] { get }

    /// A method that runs logic on the results of the `.query()` and returns
    /// those results asynchronously in an  `EventLoopFuture`.
    ///
    /// - Parameter req: The incoming `Request`.
    /// - Throws: An error if something goes wrong.
    /// - Returns: An `EventLoopFuture` containing the processed object.
    func handler(_ req: Request) throws -> EventLoopFuture<Element>


    /// A method to run database queries on a component's `QuerySubject`.
    ///
    /// - Parameter req: The incoming `Request`.
    /// - Throws: An error if something goes wrong.
    /// - Returns: A `QueryBuilder` for further querying after this `.query`.
    func query(_ req: Request) throws -> QueryBuilder<QuerySubject>
}

/// Extends `RestEndpoint` with default implementation for route registration.
public extension RestEndpoint {

    /// The empty  `pathComponents` of the `RestEndpoint`.
    var pathComponents: [PathComponent] { [] }
    
    /// Registers the component to the `Vapor` router depending on its
    /// `operationType`.
    /// 
    /// - Parameter routes: The `RoutesBuilder` to extend.
    func register(to routes: RoutesBuilder) {
        switch operationType {
        case .post:
            routes.post(pathComponents, use: handler)
        case .get:
            routes.get(pathComponents, use: handler)
        case .put:
            routes.put(pathComponents, use: handler)
        case .delete:
            routes.delete(pathComponents, use: handler)
        case .patch:
            routes.patch(pathComponents, use: handler)
        }
    }
}

/// An extension that provides a default empty database query for those
/// components that do not need custom `.query()` logic.
extension RestEndpoint {

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
