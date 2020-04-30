import Vapor
import Fluent

/// A class that wraps a component which utilizes a `.respond(with:)` modifier.
/// That allows Corvus to chain modifiers, as it gets treated as any other
/// struct conforming to `RestEndpoint`.
public final class ResponseModifier<Q: QueryEndpoint,R: CorvusResponse>:
    QueryEndpointModifier where Q.Element == R.Item
{
    
    /// The Element that is returned by the handler.
    public typealias Element = R
    
    /// The `RestEndpoint` the `.respond(with:)` modifier is attached to.
    public let modifiedEndpoint: Q
    
    /// Initializes the modifier with its underlying `RestEndpoint`.
    ///
    /// - Parameters:
    ///     - queryEndpoint: The `QueryEndpoint` which the modifer is attached
    ///     to.
    public init(_ endpoint: Q) {
        self.modifiedEndpoint = endpoint
    }
    
    /// A method which transform the restEndpoints's handler return value to a
    /// `Response`.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An `EventLoopFuture` containing the
    /// `ResponseModifier`'s `Response`.
    /// - Throws: An `Abort` error if something goes wrong.
    public func handler(_ req: Request) throws -> EventLoopFuture<Element> {
        try modifiedEndpoint.handler(req).map(R.init)
    }
}

/// An extension that adds a `.respond(with:)` modifier to `RestEndpoint`.
extension QueryEndpoint {

    /// A modifier used to transform the values returned by a component using a
    /// `CorvusResponse`.
    ///
    /// - Parameter as: A type conforming to `CorvusResponse`.
    /// - Returns: An instance of a `ResponseModifier` with the supplied
    /// `CorvusResponse`.
    public func respond<R: CorvusResponse>(
        with: R.Type
    ) -> ResponseModifier<Self, R> {
        ResponseModifier(self)
    }
}
