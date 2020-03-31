import Vapor
import Fluent

/// A class that wraps a component which utilizes a `.respond(with:)` modifier. That
/// allows Corvus to chain modifiers, as it gets treated as any other struct
/// conforming to `RestEndpoint`.
public final class ResponseModifier<Q: RestEndpoint, R: CorvusResponse>: RestEndpoint where Q.Element == R.Item {
    
    /// The `Response` of this modifier.
    public typealias Response = R
    
    /// The `RestEndpoint` the `.respond(with:)` modifier is attached to.
    public let restEndpoint: Q

    /// The HTTP operation type of the component.
    public let operationType: OperationType
    
    /// Initializes the modifier with its underlying `RestEndpoint`.
    ///
    /// - Parameters:
    ///     - queryEndpoint: The `QueryEndpoint` which the modifer is attached
    ///     to.
    public init(_ restEndpoint: Q) {
        self.restEndpoint = restEndpoint
        self.operationType = restEndpoint.operationType
    }
    
    /// A method which transform the restEndpoints's handler return value to a
    /// `Response`.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An `EventLoopFuture` containing the
    /// `ResponseModifier`'s `Response`.
    public func handler(_ req: Request)
        throws -> EventLoopFuture<Response> {
            try restEndpoint.handler(req).map(Response.init)
    }

}

/// An extension that adds a `.respond(with:)` modifier to `RestEndpoint`.
extension RestEndpoint {

    /// A modifier used to transform the values returned by a component using a
    /// `CorvusResponse`.
    ///
    /// - Parameter as: A type conforming to `CorvusResponse`.
    /// - Returns: An instance of a `ResponseModifier` with the supplied `CorvusResponse`.
    public func respond<R: CorvusResponse>(
        with: R.Type
    ) -> ResponseModifier<Self, R> {
        ResponseModifier(self)
    }
}
