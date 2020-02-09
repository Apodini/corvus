import Vapor

/// An object generating a unique string to represent a route parameter.
public struct Parameter<T: CorvusModel> {

    /// The generated unique string.
    public var id: PathComponent = .parameter(
        "\(String(describing: T.self))\(UUID().uuidString)"
    )

    /// Makes the class publicly initializable.
    public init() {}
}
