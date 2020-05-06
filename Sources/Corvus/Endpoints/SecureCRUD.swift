import Vapor
import Fluent

/// A class that contains Create, Read, Update and Delete functionality for a
/// generic type `T` conforming to `CorvusModel` grouped under a given path and
/// allows securing those resources with the `.auth()` modifier.
final class SecureCRUD<
    T: CorvusModel,
    A: CorvusModelAuthenticatable
>: CRUD<T> {

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
        _ pathComponents: [PathComponent],
        user userKeyPath: UserKeyPath,
        softDelete: Bool = false
    ) {
        self.userKeyPath = userKeyPath
        super.init(pathComponents, softDelete: softDelete)
    }

    /// The `content` of the `SecureCRUD`, containing Create, Read, Update and
    /// Delete functionality grouped under one and secured by `.auth()`.
    override public var content: Endpoint {
        Group {
            if useSoftDelete {
                Group(pathComponents) {
                    Create<T>().auth(userKeyPath)
                    ReadAll<T>().auth(userKeyPath)
                    
                    Group(parameter.id) {
                        ReadOne<T>(parameter.id).auth(userKeyPath)
                        Update<T>(parameter.id).auth(userKeyPath)
                        Delete<T>(parameter.id, softDelete: true)
                            .auth(userKeyPath)
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
            } else {
                Group(pathComponents) {
                    Create<T>().auth(userKeyPath)
                    ReadAll<T>().auth(userKeyPath)

                    Group(parameter.id) {
                        ReadOne<T>(parameter.id).auth(userKeyPath)
                        Update<T>(parameter.id).auth(userKeyPath)
                        Delete<T>(parameter.id).auth(userKeyPath)
                    }
                }
            }
        }
    }
}
