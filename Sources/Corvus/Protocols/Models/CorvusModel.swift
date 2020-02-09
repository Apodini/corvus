import Vapor
import Fluent

/// A protocol that wraps both `Model` and `Content` for convenience and is used
/// to define all models that are used in database persistency and in network
/// communication.
public protocol CorvusModel: Model, Content
where IDValue: LosslessStringConvertible {}


/// An extension that provides access to the id of an object read from the
/// database **during runtime**.
extension CorvusModel {
    
    var _$id: ID<Int> {
        guard let mirror = Mirror(reflecting: self).descendant("_id"),
            let id = mirror as? ID<Int> else {
                fatalError("id property must be declared using @ID")
        }

        return id
    }
}
