import Vapor
import Fluent

/// A class that provides functionality to read all objects of a generic type
/// `T` conforming to `CorvusModel`.
public final class ReadAll<T: CorvusModel>: ReadEndpoint {

    /// The return type of the `.handler()`.
    public typealias QuerySubject = T

    //TODO: Missing Documentation
    public let target: ReadTarget<QuerySubject>
    
    /// Initializes the component
    ///
    /// - Parameter target: A `ReadTarget` which controls where to query the item from.
    public init(_ target: ReadTarget<QuerySubject> = .existing) {
        self.target = target
    }

    /// A method to return all objects of the type `QuerySubject` from the
    /// database.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An array of `QuerySubjects`.
    public func handler(_ req: Request) throws -> EventLoopFuture<[QuerySubject]> {
        switch target.option {
        case .existing:
            return try query(req).all()
        case .all:
            return try query(req).withDeleted().all()
        case .trashed(let deletedTimestamp):
            return try query(req).withDeleted().filter(.path(deletedTimestamp.path, schema: T.schema), .notEqual, .null).all()
        }
    }

    /// A method that registers the `.handler()` to the supplied `RoutesBuilder`.
    ///
    /// - Parameter routes: A `RoutesBuilder` containing all the information
    /// about the HTTP route leading to the current component.
    public func register(to routes: RoutesBuilder) {
        routes.get(use: handler)
    }
}
