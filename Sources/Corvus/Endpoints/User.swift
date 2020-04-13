import Vapor
import Fluent

/// A class that contains Create, Read, Update and Delete functionality for a
/// generic type `T` representing a user object.
public final class User<T: CorvusModelAuthenticatable & CorvusModel>: Endpoint {

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
    public init(_ pathComponents: PathComponent..., softDelete: Bool = false) {
        self.pathComponents = pathComponents
        self.useSoftDelete = softDelete
    }

    /// The `content` of the `User`, containing Create, Read, Update and Delete
    /// functionality grouped under one.
    public var content: Endpoint {
        if useSoftDelete {
            return contentWithSoftDelete
        }
        
        return Group(pathComponents) {
            Custom<HTTPStatus>(type: .post) { req in
                let requestContent = try req.content.decode(T.self)
                return requestContent.save(on: req.db).map { .ok }
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

    /// The `content` of the `User`, containing Create, Read, Update, Delete and
    /// SoftDelete functionality grouped under one.
    public var contentWithSoftDelete: Endpoint {
        Group(pathComponents) {
            Custom<HTTPStatus>(type: .post) { req in
                let requestContent = try req.content.decode(T.self)
                return requestContent.save(on: req.db).map { .ok }
            }
            
            BasicAuthGroup<T> {
                ReadAll<T>().userAuth()
                
                Group(parameter.id) {
                    ReadOne<T>(parameter.id).userAuth()
                    Update<T>(parameter.id).userAuth()
                    Delete<T>(parameter.id, softDelete: true).userAuth()
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
