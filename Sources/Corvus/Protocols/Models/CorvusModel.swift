import Vapor
import Fluent

/// A protocol that wraps both `Model` and `Content` for convenience and is used
/// to define all models that are used in database persistency and in network
/// communication.
public protocol CorvusModel: Model, Content
where IDValue: LosslessStringConvertible {}
