import Vapor

// swiftlint:disable identifier_name
/// Describes a type that authorizes incoming requests.
public protocol Guard: Middleware {
    
    /// The error that is thrown when the authorization fails.
    /// By default `Abort(HTTPResponseStatus.forbidden)` is thrown.
    var error: Error { get }
    
    /// A closure which evaluates the authorization.
    /// This method is called by the `asyncGuard` method.
    /// If the evaluation is asynchronous, use  `asyncGuard`.
    /// - Parameter req: The incoming Request.
    func ´guard´(req: Request) throws -> Bool
    
    
    /// This is the same as the `guard` closure, but async.
    /// This method can be overriden if the evaluation is asynchronous.
    /// Otherwise overrides `guard`.
    /// By default this method calls `guard`.
    /// - Parameter req: The incomfing Request.
    func asyncGuard(req: Request) -> EventLoopFuture<Bool>
}

public extension Guard {
    
    var error: Error {
        Abort(.badRequest)
    }
    
    func ´guard´(req: Request) throws -> Bool { true }
    
    func asyncGuard(req: Request) -> EventLoopFuture<Bool> {
        return req.eventLoop.submit { try self.´guard´(req: req) }
    }
    
    func respond(
        to request: Request,
        chainingTo next: Responder
    ) -> EventLoopFuture<Response> {
        asyncGuard(req: request).flatMap {
            $0 ? next.respond(to: request)
            : request.eventLoop.makeFailedFuture(self.error)
        }
    }
}
