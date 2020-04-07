import Fluent
import Vapor

// swiftlint:disable identifier_name
public protocol CorvusModelUserToken: CorvusModel {
    
    associatedtype User: CorvusModel & Authenticatable
    var value: String { get set }
    var user: User { get set }
    var isValid: Bool { get }
}

extension CorvusModelUserToken {

    init(id: Self.IDValue? = nil, value: String, userId: User.IDValue) {
        self.init()
        self.value = value
        _$user.id = userId
     }
}

extension CorvusModelUserToken {
    
    public static func authenticator(
        database: DatabaseID? = nil
    ) -> CorvusModelUserTokenAuthenticator<Self> {
        CorvusModelUserTokenAuthenticator<Self>(database: database)
    }
    
    var _$value: Field<String> {
        guard let mirror = Mirror(reflecting: self).descendant("_value"),
            let token = mirror as? Field<String> else {
                fatalError("value property must be declared using @Field")
        }

        return token
    }

    var _$user: Parent<User> {
        guard let mirror = Mirror(reflecting: self).descendant("_user"),
            let user = mirror as? Parent<User> else {
                fatalError("user property must be declared using @Parent")
        }

        return user
    }
}

public struct CorvusModelUserTokenAuthenticator<T: CorvusModelUserToken>:
BearerAuthenticator
{
    public typealias User = T.User
    public let database: DatabaseID?

    public func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) -> EventLoopFuture<User?> {
        let db = request.db(self.database)
        return T.query(on: db)
            .filter(\._$value == bearer.token)
            .first()
            .flatMap
        { token -> EventLoopFuture<User?> in
            guard let token = token else {
                return request.eventLoop.makeSucceededFuture(nil)
            }
            guard token.isValid else {
                return token.delete(on: db).map { nil }
            }
            return token._$user.get(on: db)
                .map { $0 }
        }
    }
}
