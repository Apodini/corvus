import Vapor
import JWT

struct CorvusJWTAuthenticator<P: JWTPayload & Authenticatable>: JWTAuthenticator {
    func authenticate(jwt: P, for request: Request) -> EventLoopFuture<Void> {
        request.auth.login(jwt)
        return request.eventLoop.makeSucceededFuture(())
    }
}
