import Vapor
import Fluent

/// A class that contains Create, Read, Update and Delete functionality for a
/// generic type `T` conforming to `CorvusModel` grouped under a given path and
/// allows securing those resources with the `.auth()` modifier.
public final class SecureCRUD<
    T: CorvusModel,
    A: CorvusModelAuthenticatable
>: Endpoint {

    /// The route path to the parameters.
    let pathComponents: [PathComponent]

    /// A property to generate route parameter placeholders.
    let parameter = Parameter<T>()

    /// Indicates whether soft delete should be included or not.
    let useSoftDelete: Bool
    
    /// The `KeyPath` to the user property of the `QuerySubject` which is to be
    /// authenticated.
    public typealias UserKeyPath = KeyPath<
        T,
        T.Parent<A>
    >
    
    /// The path to the property to authenticate for.
    public var userKeyPath: UserKeyPath
    
    /// Initializes the component with one or more route path components.
    ///
    /// - Parameter pathComponents: One or more `PathComponents` identifying the
    /// path to the operations defined by the `SecureCRUD` component.
    /// - Parameter softDelete: Enable/Disable soft deletion of Models.
    /// - Parameter userKeyPath: The path to the user property of the model `T`
    /// the component operates on.
    public init(
        _ pathComponents: PathComponent...,
        user userKeyPath: UserKeyPath,
        softDelete: Bool = true
    ) {
        self.pathComponents = pathComponents
        self.useSoftDelete = softDelete
        self.userKeyPath = userKeyPath
    }

    /// The `content` of the `SecureCRUD`, containing Create, Read, Update and
    /// Delete functionality grouped under one and secured by `.auth()`.
    public var content: Endpoint {
        if useSoftDelete {
            return contentWithSoftDelete
        }
        
        return Group(pathComponents) {
            Create<T>().auth(userKeyPath)
            ReadAll<T>().auth(userKeyPath)

            Group(parameter.id) {
                ReadOne<T>(parameter.id).auth(userKeyPath)
                Update<T>(parameter.id).auth(userKeyPath)
                Delete<T>(parameter.id).auth(userKeyPath)
            }
        }
    }
    
    /// The `content` of the `SecureCRUD`, containing Create, Read, Update,
    /// Delete and SoftDelete functionality grouped under one and secured by
    /// `.auth()`.
    public var contentWithSoftDelete: Endpoint {
        Group(pathComponents) {
            Create<T>().auth(userKeyPath)
            ReadAll<T>().auth(userKeyPath)
            
            Group(parameter.id) {
                ReadOne<T>(parameter.id).auth(userKeyPath)
                Update<T>(parameter.id).auth(userKeyPath)
                SoftDelete<T>(parameter.id).auth(userKeyPath)
            }
            
            Group("trash") {
                ReadAll<T>(.trashed)
                Group(parameter.id) {
                    ReadOne<T>(parameter.id, .trashed).auth(userKeyPath)
                    Delete<T>(parameter.id).auth(userKeyPath)
                    
                    Group("restore") {
                        Restore<T>(parameter.id).auth(userKeyPath)
                    }
                }
            }
        }
    }
}
