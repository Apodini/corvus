import Vapor

/// A class that wraps a component which utilizes an `.dto()` modifier. This
/// allows Corvus to chain modifiers, as it gets treated as any other struct
/// conforming to `UpdateEndpoint`.
public final class UpdateClosureModifier<
    U: UpdateEndpoint,
    D: Decodable>:
RestModifier<U>
where U.Element == U.QuerySubject {
    public let patch: (D, QuerySubject) throws -> Void
    
    /// Initializes the modifier with its underlying `UpdateEndpoint`.
    ///
    /// - Parameter endpoint: The `QueryEndpoint` which the modifer is attached
    /// to.
    public init(
        _ updateEndpoint: U,
        _ patch: @escaping (D, QuerySubject
    ) throws -> Void) {
        self.patch = patch
        super.init(updateEndpoint)
    }

    /// A method which decodes the `DTO`from the body of the `Request`
    ///  and executes its `patch()` function to
    ///  update the model in the database.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An `EventLoopFuture` containing the `ResponseEncodable`
    /// defined by the `DTO`s `Response` type.
    /// Typically this is the updated model.
    public override func handler(_ req: Request) throws -> EventLoopFuture<Element> {
        let patch = try req.content.decode(D.self)

        return try modifiedEndpoint.query(req)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { model -> QuerySubject in
                try self.patch(patch, model)
                return model
            }
            .flatMap { model in
                model.update(on: req.db).map { model }
            }
    }
}

/// A class that wraps a component which utilizes an `.dto()` modifier. This
/// allows Corvus to chain modifiers, as it gets treated as any other struct
/// conforming to `AuthEndpoint`.
public final class UpdateTypeModifier<
    U: UpdateEndpoint,
    D: UpdateDTO>:
RestModifier<U>, UpdateEndpoint
where U.Element == U.QuerySubject, D.Element == U.QuerySubject {

    /// A method which decodes the `DTO`from the body of the `Request`
    ///  and executes its `patch()` function to
    ///  update the model in the database.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An `EventLoopFuture` containing the `ResponseEncodable`
    /// defined by the `DTO`s `Response` type.
    /// Typically this is the updated
    public override func handler(_ req: Request) throws -> EventLoopFuture<Element> {
        if let validator = D.self as? Validatable.Type {
            try validator.validate(req)
        }
        
        let patch = try req.content.decode(D.self)

        return try modifiedEndpoint.query(req)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { model -> QuerySubject in
                try patch.patch(model: model)
                return model
            }
            .flatMap { model in
                model.update(on: req.db).map { model }
            }
    }
}

public extension UpdateEndpoint {
    func mediator<D: Decodable>(
        _ type: D.Type,
        patch: @escaping (D, QuerySubject) throws -> Void
    ) -> UpdateClosureModifier<Self, D> {
        UpdateClosureModifier<Self, D>(self, patch)
    }
    
    func mediator<U: UpdateDTO>(
        _ type: U.Type
    ) -> UpdateTypeModifier<Self, U> {
        UpdateTypeModifier<Self, U>(self)
    }
}
