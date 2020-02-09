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
}
