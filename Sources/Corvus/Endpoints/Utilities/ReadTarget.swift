import Vapor
import Fluent

/// Describes the target of a read operation, either all objects, only existing
/// objects, or only trashed (soft-deleted) objects.
public struct ReadTarget<T: CorvusModel> {

    /// An enum describing the different options for read targets.
    enum Option<T: CorvusModel> {
        case all
        case existing
        case trashed(T.Timestamp<DefaultTimestampFormat>)
    }

    /// The type of target to be read.
    let option: Option<T>

    /// Initializes a `ReadTarget` with the `.all` option.
    public static var all: ReadTarget<T> { .init(option: Option<T>.all) }

    /// Initializes a `ReadTarget` with the `.existing` option.
    public static var existing: ReadTarget<T> {
        .init(option: Option<T>.existing)
    }

    /// Initializes a `ReadTarget` with the `.trashed` option.
    public static var trashed: ReadTarget<T> {
        guard let timestamp = T.deletedTimestamp else {
              preconditionFailure("""
                   There must a @Timestamp field in your model with a
                   `TimestampTrigger` set to .delete
               """)
        }

        return .init(option: Option<T>.trashed(timestamp))
    }
}
