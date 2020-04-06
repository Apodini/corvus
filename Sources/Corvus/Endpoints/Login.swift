import Vapor
import Fluent

/// A class that provides functionality to log in a user with username and
/// password credentials sent in a HTTP POST `Request` and save a token for
/// that user.
public final class Login<T: CorvusModelUserToken & ResponseEncodable>: Endpoint
where T.User: ModelUser {

    /// The route for the login functionality
    let path: PathComponent

    /// Initializes the component with a path to its functionality.
    ///
    /// - Parameter path: A `PathComponent` describing the path to the endpoint.
    public init(_ path: PathComponent) {
        self.path = path
    }

    /// Logs in a user passed in a `Request` by creating a bearer token for it
    /// and saving it in the database.
    ///
    /// - Parameter req: An incoming HTTP `Request`.
    /// - Returns: An `EventLoopFuture` containing the created `CorvusToken`.
    public func handler(_ req: Request) throws -> EventLoopFuture<T> {
        let user = try req.auth.require(T.User.self)
        let token = T.init(value: [UInt8].random(count: 16).base64, userId: try user.requireID())
      
        return token.save(on: req.db).map { token }
    }

    /// A method that registers the `handler()` to the supplied `RoutesBuilder`.
    /// It also registers basic authentication middleware using `CorvusUser`.
    ///
    /// - Parameter routes: A `RoutesBuilder` containing all the information
    /// about the HTTP route leading to the current component.
    public func register(to routes: RoutesBuilder) {
        let guardedRoutesBuilder = routes.grouped(
            T.User.authenticator().middleware()
        )
        
        guardedRoutesBuilder.post(path, use: handler)
    }
}
