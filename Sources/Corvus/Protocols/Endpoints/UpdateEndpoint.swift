import Vapor
import Fluent

/// A special `AuthEndpoint` used to provide a common interface for `Update`
/// components so they can access their own `.auth` modifier.
public protocol UpdateEndpoint: AuthEndpoint {}
