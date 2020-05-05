import Vapor
import Fluent

/// A class that contains Create, Read, Update and Delete functionality for a
/// generic type `T` conforming to `CorvusModel` grouped under a given path.
public class CRUD<T: CorvusModel>: Endpoint {

    /// The route path to the parameters.
    let pathComponents: [PathComponent]

    /// A property to generate route parameter placeholders.
    let parameter = Parameter<T>()

    /// Indicates whether soft delete should be included or not.
    let useSoftDelete: Bool
    
    /// All the endpoints used by `CRUD`.
    var create: Create<T>
    var readOne: ReadOne<T>
    var readAll: ReadAll<T>
    var update: Update<T>
    var delete: Delete<T>
    var softDelete: Delete<T>
    var restore: Restore<T>
    
    /// Initializes the component with one or more route path components.
    ///
    /// - Parameters:
    ///     - pathComponents: One or more `PathComponents` identifying the path
    ///     to the operations defined by the `CRUD` component.
    ///     - softDelete: Enable/Disable soft deletion of Models.
    public init(_ pathComponents: PathComponent..., softDelete: Bool = false) {
        self.pathComponents = pathComponents
        self.useSoftDelete = softDelete
        create = Create<T>()
        readOne = ReadOne<T>(parameter.id)
        readAll = ReadAll<T>()
        update = Update<T>(parameter.id)
        delete = Delete<T>(parameter.id)
        self.softDelete = Delete<T>(parameter.id, softDelete: true)
        restore = Restore<T>(parameter.id)
    }
    
    /// Initializes the component with multiple route path components.
    ///
    /// - Parameters:
    ///     - pathComponents: One or more `PathComponents` identifying the path
    ///     to the operations defined by the `CRUD` component.
    ///     - softDelete: Enable/Disable soft deletion of Models.
    init(_ pathComponents: [PathComponent], softDelete: Bool = false) {
        self.pathComponents = pathComponents
        self.useSoftDelete = softDelete
        create = Create<T>()
        readOne = ReadOne<T>(parameter.id)
        readAll = ReadAll<T>()
        update = Update<T>(parameter.id)
        delete = Delete<T>(parameter.id)
        self.softDelete = Delete<T>(parameter.id, softDelete: true)
        restore = Restore<T>(parameter.id)
    }

    /// The `content` of the `CRUD`, containing Create, Read, Update and Delete
    /// functionality grouped under one.
    public var content: Endpoint {
        if useSoftDelete {
            return contentWithSoftDelete
        }
        
        return Group(pathComponents) {
            Create<T>()
            ReadAll<T>()

            Group(parameter.id) {
                ReadOne<T>(parameter.id)
                Update<T>(parameter.id)
                Delete<T>(parameter.id)
            }
        }
    }

    /// The `content` of the `CRUD`, containing Create, Read, Update, Delete and
    /// SoftDelete functionality grouped under one.
    public var contentWithSoftDelete: Endpoint {
        Group(pathComponents) {
            Create<T>()
            ReadAll<T>()
            
            Group(parameter.id) {
                ReadOne<T>(parameter.id)
                Update<T>(parameter.id)
                Delete<T>(parameter.id, softDelete: true)
            }
            
            Group("trash") {
                ReadAll<T>(.trashed)
                Group(parameter.id) {
                    ReadOne<T>(parameter.id, .trashed)
                    Delete<T>(parameter.id)
                    
                    Group("restore") {
                        Restore<T>(parameter.id)
                    }
                }
            }
        }
    }
}
///// An extension that adds modifiers to `CRUD` components.
//public extension CRUD {
//
//    func filter(_ filter: ModelValueFilter<T>) -> CRUD {
//        readOne = readOne.filter(filter)
//        readAll = readAll.filter(filter)
//        return self
//    }
//
//    func children<C: CorvusModel>(_ path: KeyPath<T, T.Children<C>>) -> CRUD {
//        readOne = readOne.children(path)
//        readAll = readAll.children(path)
//        return self
//    }
//
//    func auth<U: CorvusModelAuthenticatable>(
//        _ user: KeyPath<T, T.Parent<U>>
//    ) -> CRUD {
//        create = create.auth(user)
//        readOne = readOne.auth(user)
//        readAll = readAll.auth(user)
//        update = update.auth(user)
//        delete = delete.auth(user)
//        softDelete = softDelete.auth(user)
//        return self
//    }
//}
