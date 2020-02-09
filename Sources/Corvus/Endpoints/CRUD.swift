import Vapor

/// A class that contains Create, Read, Update and Delete functionality for a
/// generic type `T` conforming to `CorvusModel` grouped under a given path.
public final class CRUD<T: CorvusModel>: Endpoint {

    /// The route path to the parameters.
    let pathComponents: [PathComponent]

    /// A property to generate route parameter placeholders.
    let parameter = Parameter<T>()

    /// Initializes the component with one or more route path components.
    ///
    /// - Parameter pathComponents: One or more `PathComponents` identifying the
    /// path to the operations defined by the `CRUD` component.
    public init(_ pathComponents: PathComponent...) {
        self.pathComponents = pathComponents
    }

    /// The `content` of the `CRUD`, containing Create, Read, Update and Delete
    /// functionality grouped under one.
    public var content: Endpoint {
        Group(pathComponents) {
            Create<T>()
            ReadAll<T>()

            Group(parameter.id) {
                ReadOne<T>(parameter.id)
                Update<T>(parameter.id)
                Delete<T>(parameter.id)
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
