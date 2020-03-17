import Vapor

/// A class that contains Create, Read, Update and Delete functionality for a
/// generic type `T` conforming to `CorvusModel` grouped under a given path.
public final class CRUD<T: CorvusModel>: Endpoint {

    //TODO: Missing Documentation
    public typealias DeletedAtKeyPath = KeyPath<T, T.Timestamp>
    
    /// The route path to the parameters.
    let pathComponents: [PathComponent]

    /// A property to generate route parameter placeholders.
    let parameter = Parameter<T>()

    //TODO: Missing Documentation
    let deletedAtKey: DeletedAtKeyPath?
    
    /// Initializes the component with one or more route path components.
    ///
    /// - Parameter pathComponents: One or more `PathComponents` identifying the
    /// path to the operations defined by the `CRUD` component.
    public init(_ pathComponents: PathComponent..., trash: DeletedAtKeyPath? = nil) {
        self.pathComponents = pathComponents
        self.deletedAtKey = trash
    }

    /// The `content` of the `CRUD`, containing Create, Read, Update and Delete
    /// functionality grouped under one.
    public var content: Endpoint {
        if let deletedAtKey = deletedAtKey {
            return content(with: deletedAtKey)
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
    
    func content(with deletedAtKey: DeletedAtKeyPath) -> Endpoint {
        Group(pathComponents) {
            Create<T>()
            ReadAll<T>()
            
            Group(parameter.id) {
                ReadOne<T>(parameter.id)
                Update<T>(parameter.id)
                Delete<T>(parameter.id)
            }
            
            Group("trash") {
                ReadAll<T>(.trashed(deletedAtKey))
                Group(parameter.id) {
                    ReadOne<T>(parameter.id, .trashed(deletedAtKey))
                    Delete<T>(parameter.id, .trashed(deletedAtKey))
                    
                    Group("restore") {
                        Restore<T>(parameter.id, deletedAtKey: deletedAtKey)
                    }
                }
            }
        }
    }

    /// A method that invokes the `register` function for the component's
    /// `content`.
    ///
    /// - Parameter routes: A `RoutesBuilder` containing all the information
    /// about the HTTP route leading to the current component.
    public func register(to routes: RoutesBuilder) {
        content.register(to: routes)
    }
}
