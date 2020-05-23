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
    /// - Parameters:
    ///     - pathComponents: One or more `PathComponents` identifying the path
    ///     to the operations defined by the `CRUD` component.
    ///     - softDelete: Enable/Disable soft deletion of Models.
    public init(_ pathComponents: PathComponent..., softDelete: Bool = false) {
        self.pathComponents = pathComponents
        self.useSoftDelete = softDelete
    }

    /// The `content` of the `User`, containing Create, Read, Update and Delete
    /// functionality grouped under one.
    public var content: Endpoint {
        Group(pathComponents) {
            Custom<T, T>(type: .post) { req in
                let requestUser = try req.content.decode(T.self)
                let passwordHash = try Bcrypt.hash(requestUser.password)
                 
                return T
                    .query(on: req.db)
                    .filter(\T._$username == requestUser.username)
                    .first()
                    .flatMapThrowing { existingUser in
                        guard existingUser == nil else {
                            throw Abort(.badRequest)
                        }
                    }
                    .flatMap {
                        requestUser.password = passwordHash
                        return requestUser.save(on: req.db).map { requestUser }
                    }
            }.respond(with: UserResponse.self)
            
            if useSoftDelete {
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
            } else {
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
    }
}

/// Defines a custom response so that only username and id are returned when a
/// user is created.
struct UserResponse<U: CorvusModelAuthenticatable>: CorvusResponse {
    
    /// Identifier of the user.
    let id: U.IDValue?
    
    /// Username of the user.
    let username: String
    
    /// Initializes a user response with a user object.
    /// - Parameter user: The user object to respond with.
    init(item user: U) {
        self.id = user.id
        self.username = user.username
    }
}
