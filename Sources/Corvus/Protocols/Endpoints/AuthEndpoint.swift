import Vapor
import Fluent

/// A special `QueryEndpoint` used to provide a common interface for endpoints
/// which provide access to the `.auth()` modifier.
public protocol AuthEndpoint: QueryEndpoint {}
