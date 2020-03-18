import Vapor

//TODO: Missing Documentation
public struct ReadTarget<T: CorvusModel> {
    enum Option<T: CorvusModel> {
        case all
        case existing
        case trashed(T.Timestamp)
    }
    
    let option: Option<T>
    
    public static var all: ReadTarget<T> { .init(option: Option<T>.all) }
    public static var existing: ReadTarget<T> { .init(option: Option<T>.existing) }
    
    public static var trashed: ReadTarget<T> {
        guard let timestamp = T.deletedTimestamp else {
            preconditionFailure("There must a @Timestamp field in your model with a `TimestampTrigger` set to .delete")
        }

        return .init(option: Option<T>.trashed(timestamp))
    }
}
