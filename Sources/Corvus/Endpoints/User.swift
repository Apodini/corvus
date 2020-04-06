import Vapor
import Fluent

/// A class that contains Create, Read, Update and Delete functionality for a
/// generic type `T` conforming to `CorvusModel` grouped under a given path.
public final class User<T: CorvusModelUser>: Endpoint {

    /// The route path to the parameters.
    let pathComponents: [PathComponent]

    /// A property to generate route parameter placeholders.
    let parameter = Parameter<T>()

    /// Indicates wether soft delete should be included or not.
    let useSoftDelete: Bool
    
    /// Initializes the component with one or more route path components.
    ///
    /// - Parameter pathComponents: One or more `PathComponents` identifying the
    /// path to the operations defined by the `CRUD` component.
    /// - Parameter softDelete: Enable/Disable soft deletion of Models.
    public init(_ pathComponents: PathComponent..., softDelete: Bool = true) {
        self.pathComponents = pathComponents
        self.useSoftDelete = softDelete
    }

    /// The `content` of the `CRUD`, containing Create, Read, Update and Delete
    /// functionality grouped under one.
    public var content: Endpoint {
        if useSoftDelete {
            return contentWithSoftDelete
        }
        
        return Group(pathComponents) {
            Custom<String>(type: .post) { req in
                let requestContent = try req.content.decode(T.self)
                let user = try T.init(password: requestContent.passwordHash, name: requestContent.name) // This works because initializers of CorvusModelUser and CorvusUser are equal, what happens if not?
                return user
                    .save(on: req.db)
                    .flatMapThrowing { user.name }
            }
            
            BasicAuthGroup<T> {
                ReadAll<T>().userAuth()
                Group(parameter.id) {
                    ReadOne<T>(parameter.id).userAuth()
                    Update<T>(parameter.id).userAuth()
                    Delete<T>(parameter.id).userAuth()
                }
            }
        }
    }

    /// The `content` of the `CRUD`, containing Create, Read, Update, Delete and
    /// SoftDelete functionality grouped under one.
    public var contentWithSoftDelete: Endpoint {
        Group(pathComponents) {
            Custom<String>(type: .post) { req in
                let requestContent = try req.content.decode(T.self)
                let user = try T.init(password: requestContent.passwordHash, name: requestContent.name)
                return user
                    .save(on: req.db)
                    .flatMapThrowing { user.name }
            }
            
            BasicAuthGroup<T> {
                ReadAll<T>().userAuth()
                
                Group(parameter.id) {
                    ReadOne<T>(parameter.id).userAuth()
                    Update<T>(parameter.id).userAuth()
                    SoftDelete<T>(parameter.id).userAuth()
                }
                
                Group("trash") {
                    ReadAll<T>(.trashed).userAuth()
                    Group(parameter.id) {
                        ReadOne<T>(parameter.id, .trashed).userAuth()
                        Delete<T>(parameter.id).userAuth()
                        
                        Group("restore") {
                            Restore<T>(parameter.id).userAuth()
                        }
                    }
                }
            }
        }
    }
}
