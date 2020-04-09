import Vapor

/// `CorvusResponse` is a wrapper type for the result of`QueryEndpoint`s. Can
/// be used to add metadata to a response.
///
public protocol CorvusResponse: Content {
    
    /// The item is equivalent to the `QueryEndpoint`'s `QuerySubject`.
    associatedtype Item
    
    /// Initialises a `CorvusResponse` with a given item.
    /// Normally this is the result of the `QueryEndpoints`'s handler function.
    ///
    /// - Parameter item: The item to initialize the response with.
    init(item: Item)
}
