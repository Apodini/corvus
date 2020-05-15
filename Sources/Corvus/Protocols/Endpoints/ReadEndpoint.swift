import Vapor
import Fluent

/// A special `AuthEndpoint` used to provide a common interface for endpoints
/// which provide access to modifiers that are applcable for Database read
/// requests
public protocol ReadEndpoint: AuthEndpoint {}

extension ReadEndpoint {
    
    public var operationType: OperationType { .get }
}
