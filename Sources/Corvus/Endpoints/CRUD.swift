import Vapor

/// A class that contains Create, Read, Update and Delete functionality for a
/// generic type `T` conforming to `CorvusModel` grouped under a given path.
public final class CRUD<T: CorvusModel>: Endpoint {

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
                SoftDelete<T>(parameter.id)
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
