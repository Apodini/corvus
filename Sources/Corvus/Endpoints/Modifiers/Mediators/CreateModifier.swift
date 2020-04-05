import Vapor
import Fluent

/// A class that wraps a component which utilizes an `.dto()` modifier. This
/// allows Corvus to chain modifiers, as it gets treated as any other struct
/// conforming to `CreateEndpoint`.
public final class CreateTypeModifier<
    C: CreateEndpoint,
    D: CreateDTO>:
RestModifier<C>, CreateEndpoint
where D.Element == C.QuerySubject, D.Element == C.Element {

    /// A method which decodes the `DTO`from the body of the `Request`
    ///  and executes its `save()` function to update the model in the database.
    ///
    /// - Parameter req: An incoming `Request`.
    /// - Returns: An `EventLoopFuture` containing the `ResponseEncodable`
    /// defined by the `DTO`s `Response` type.
    /// Typically this is the updated model.
    override public func handler(_ req: Request)
        throws -> EventLoopFuture<Element>
    {
        if let validator = D.self as? Validatable.Type {
            try validator.validate(req)
        }
        
        let dto = try req.content.decode(D.self)
        let dtoMirror = Mirror(reflecting: dto)
        let item = try dto.model(selfMirror: dtoMirror)

        return item.create(on: req.db)
            .flatMapThrowing {
                try dto.children(for: item, selfMirror: dtoMirror)
                    .map { $0(req.db) }
                    .flatten(on: req.eventLoop)
            }
            .flatMap { $0 }
            .map { item }
    }
}

extension CreateEndpoint {
    public func mediator<D: CreateDTO>(
        _ type: D.Type
    ) -> CreateTypeModifier<Self, D> {
        CreateTypeModifier<Self, D>(self)
    }
}
