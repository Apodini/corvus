import Vapor
import Fluent

/// A class that wraps a component which utilizes a `.filter()` modifier. That
/// allows Corvus to chain modifiers, as it gets treated as any other struct
/// conforming to `ReadEndpoint`.
public final class FilterModifier<
    R: ReadEndpoint
>: ReadEndpoint {
    
    /// The return value of the `.query()`, so the type being operated on in
    /// the current component.
    public typealias QuerySubject = R.QuerySubject
    
    /// The return type for the `.handler()` modifier.
    public typealias Element = [QuerySubject]

    /// The filter passed to the `.filter()` modifier. It is an alias for
    /// `Fluent's` `ModelValueFilter`.
    public typealias Filter = ModelValueFilter<QuerySubject>

    /// The filter of the modifier.
    public let filter: Filter

    /// The instance of `Endpoint` the `RestEndpointModifier` is modifying.
    let modifiedEndpoint: R
    
    /// Initializes the modifier with its underlying `QueryEndpoint` and its
    /// `filter`.
    ///
    /// - Parameters:
    ///     - queryEndpoint: The `QueryEndpoint` which the modifer is attached
    ///     to.
    ///     - filter: A Fluent `ModelValueFilter` which represents a database
    ///     query to filter values by.
    public init(_ readEndpoint: R, filter: ModelValueFilter<QuerySubject>) {
        self.modifiedEndpoint = readEndpoint
        self.filter = filter
    }

    /// Builds a query on the `queryEndpoint`'s query by attaching a filter.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: A `QueryBuilder`, which represents a `Fluent` query after
    /// having attached a filter to the `queryEndpoint`'s query.
    /// - Throws: An `Abort` error if the item is not found.
    public func query(_ req: Request) throws -> QueryBuilder<QuerySubject> {
        try modifiedEndpoint.query(req).filter(filter)
    }

    /// A method to return objects found in the `.query()` from the database.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An `EventLoopFuture` containing an array of the
    /// `FilterModifier`'s `QuerySubject`.
    /// - Throws: An `Abort` error if the item is not found.
    public func handler(_ req: Request) throws -> EventLoopFuture<Element> {
        try query(req).all()
    }
}

/// An extension that adds a `.filter()` modifier to `ReadEndpoints`.
extension ReadEndpoint {

    /// A modifier used to filter the values returned by a component using a
    /// passed in `ModelValueFilter`.
    ///
    /// - Parameter filter: A `ModelValueFilter` to filter values by.
    /// - Returns: An instance of a `FilterModifier` with the supplied filter.
    public func filter(
        _ filter: FilterModifier<Self>.Filter
    ) -> FilterModifier<Self> {
        FilterModifier(self, filter: filter)
    }
}
