import Vapor
import Fluent

/// A protocol that wraps both `Model` and `Content` for convenience and is used
/// to define all models that are used in database persistency and in network
/// communication.
public protocol CorvusModel: Model, Content
where IDValue: LosslessStringConvertible {}

/// Extends `CorvusModel` to allow access to its deletion timestamp.
public extension CorvusModel {

    /// The timestamp at which a `CorvusModel` was soft deleted.
    static var deletedTimestamp: Timestamp<DefaultTimestampFormat>? {
        Self().properties
            .compactMap({
                $0 as? TimestampProperty<Self, DefaultTimestampFormat>
            })
            .filter({ $0.trigger == .delete })
            .first
    }
}
