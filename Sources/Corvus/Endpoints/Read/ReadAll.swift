import Vapor
import Fluent

/// A class that provides functionality to read all objects of a generic type
/// `T` conforming to `CorvusModel`.
public final class ReadAll<T: CorvusModel>: ReadEndpoint {

    /// The return type of the `.handler()`.
    public typealias QuerySubject = T

    /// A property that describes if only existing, only trashed or both objects
    /// should be read from the database.
    public let target: ReadTarget<QuerySubject>
    
    /// Initializes the component
    ///
    /// - Parameter target: A `ReadTarget` which controls where to query the
    /// item from.
    public init(_ target: ReadTarget<QuerySubject> = .existing) {
        self.target = target
    }

    /// A method to return all objects of the type `QuerySubject` from the
    /// database, depending on the `target`.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An array of `QuerySubjects`.
    /// - Throws: An `Abort` error if something goes wrong.
    public func handler(_ req: Request) throws ->
        EventLoopFuture<[QuerySubject]>
    {
        switch target.option {
        case .existing:
            return try query(req)
                .all()
        case .all:
            return try query(req)
                .withDeleted()
                .all()
        case .trashed(let deletedTimestamp):
            return try query(req)
                .withDeleted()
                .filter(
                    .path(deletedTimestamp.path, schema: T.schema),
                    .notEqual,
                    .null
                )
                .all()
        }
    }
}
