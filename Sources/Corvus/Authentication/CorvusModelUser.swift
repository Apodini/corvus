import Fluent
import Vapor

public protocol CorvusModelUser: CorvusModel, Authenticatable {
    
    var name: String { get set }
    var passwordHash: String { get set }
    func verify(password: String) throws -> Bool
}

extension CorvusModelUser {

    internal init(id: Self.IDValue? = nil, password: String, name: String) throws {
        self.init()
        self.name = name
        self.passwordHash = try Bcrypt.hash(password)
     }
}

extension CorvusModelUser {
    public static func authenticator(
        database: DatabaseID? = nil
    ) -> CorvusModelUserAuthenticator<Self> {
        CorvusModelUserAuthenticator<Self>(database: database)
    }

    var _$name: Field<String> {
        guard let mirror = Mirror(reflecting: self).descendant("_name"),
            let username = mirror as? Field<String> else {
                fatalError("name property must be declared using @Field")
        }

        return username
    }

    var _$passwordHash: Field<String> {
        guard let mirror = Mirror(reflecting: self).descendant("_passwordHash"),
            let passwordHash = mirror as? Field<String> else {
                fatalError("passwordHash property must be declared using @Field")
        }

        return passwordHash
    }
}

public struct CorvusModelUserAuthenticator<User>: BasicAuthenticator
    where User: CorvusModelUser
{
    public let database: DatabaseID?

    public func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) -> EventLoopFuture<User?> {
        User.query(on: request.db(self.database))
            .filter(\._$name == basic.username)
            .first()
            .flatMapThrowing
        {
            guard let user = $0 else {
                return nil
            }
            guard try user.verify(password: basic.password) else {
                return nil
            }
            return user
        }
    }
}
