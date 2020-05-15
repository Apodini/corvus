import Vapor
import Fluent

/// A special `RestEndpoint` used to provide a common interface for endpoints
/// which provide access to the `.auth()` modifier.
public protocol AuthEndpoint: RestEndpoint {}
