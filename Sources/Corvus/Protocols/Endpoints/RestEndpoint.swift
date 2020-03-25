import Vapor

public protocol RestEndpoint: Endpoint {

    /// The type returned after from the `.handler()`.
    associatedtype Element: ResponseEncodable

    /// The HTTP method of the functionality of the component.
    var operationType: OperationType { get }

    /// An array of `PathComponent` describing the path that the
    /// `TypedEndpoint` extends.
    var pathComponents: [PathComponent] { get }

    /// A method that runs logic on the results of the `.query()` and returns
    /// those results asynchronously in an  `EventLoopFuture`.
    func handler(_ req: Request) throws -> EventLoopFuture<Element>
}

public extension RestEndpoint {
    var pathComponents: [PathComponent] { [] }
    
    func register(to routes: RoutesBuilder) {
        switch operationType {
        case .post:
            routes.post(pathComponents, use: handler)
        case .get:
            routes.get(pathComponents, use: handler)
        case .put:
            routes.put(pathComponents, use: handler)
        case .delete:
            routes.delete(pathComponents, use: handler)
        case .patch:
            routes.patch(pathComponents, use: handler)
        }
    }
}
