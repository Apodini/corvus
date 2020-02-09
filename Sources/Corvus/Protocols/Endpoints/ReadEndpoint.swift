import Vapor
import Fluent

/// A protocol that provides a common interface for components that provide
/// logic to read objects.
public protocol ReadEndpoint: AuthEndpoint {}

/// An extension to provide a default value for a `ReadEndpoint`'s
/// `operationType`, which is always GET.
extension ReadEndpoint {

    /// The default `operationType` is GET.
    public var operationType: OperationType { .get }
}
