/// A function builder used to aggregate multiple `Endpoints` into a single
/// `Endpoint`.
@_functionBuilder
public enum EndpointBuilder {

    /// A method that transforms multiple `Endpoints` into one.
    ///
    /// - Parameter endpoints: One or more `Endpoints` to transform into a
    /// single endpoint.
    public static func buildBlock(_ endpoints: Endpoint...) -> Endpoint {
        endpoints
    }
    
    /// A method that enables the use of if-else in the Corvus DSL. This returns
    /// `Endpoints` within the if-part.
    ///
    /// - Parameter first: One or more `Endpoints` to transform into a
    /// single endpoint.
    public static func buildEither(first: Endpoint) -> Endpoint {
        first
    }
    
    /// A method that enables the use of if-else in the Corvus DSL. This returns
    /// `Endpoints` within the else-part.
    ///
    /// - Parameter first: One or more `Endpoints` to transform into a
    /// single endpoint.
    public static func buildEither(second: Endpoint) -> Endpoint {
        second
    }
    
}
