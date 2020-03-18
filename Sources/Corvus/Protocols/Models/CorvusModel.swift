import Vapor
import Fluent

/// A protocol that wraps both `Model` and `Content` for convenience and is used
/// to define all models that are used in database persistency and in network
/// communication.
public protocol CorvusModel: Model, Content
where IDValue: LosslessStringConvertible {}

//TODO: Missing Documentation
public extension CorvusModel {
    static var deletedTimestamp: Timestamp? {
        Self().properties
            .compactMap({ $0 as? TimestampProperty<Self> })
            .filter({ $0.trigger == .delete })
            .first
    }
}

