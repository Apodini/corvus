import Vapor
import Fluent

/// A protocol that defines Data Transfer Objects
/// that provide logic to save models to the database.
public protocol CreateDTO: Decodable {
    
    /// The associated `CorvusModel`
    associatedtype Element: CorvusModel
    
    typealias ConnectField<Value: Codable>
        = FieldConnector<Element, Value>
    
    typealias ConnectChildrenDTO<Value: CreateDTO>
        = ChildrenDTOConnector<Element, Value>
    
    typealias ConnectChildren<Value: Model>
        = ChildrenConnector<Element, Value>
    
    typealias ConnectEnum<Value: Codable & RawRepresentable>
        = EnumConnector<Element, Value> where Value.RawValue == String
    
    typealias ConnectParent<Value: CorvusModel>
        = ParentConnector<Element, Value>
    
    init()
}

public extension CreateDTO {

    init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: FieldCodingKey.self)
        try decodeFields(from: container)
    }
    
    internal func model(selfMirror: Mirror) throws -> Element {
        let model = Element()
        try valueFields(selfMirror).forEach { try $0.set(on: model) }
        enumFields(selfMirror).forEach { $0.set(on: model) }
        return model
    }
    
    internal func children(for item: Element, selfMirror: Mirror) throws -> [(Database) -> EventLoopFuture<Void>] {
        try childrenFields(selfMirror).map { try $0.relationFactory(for: item) }
    }
}

// Helpers
extension CreateDTO {
    internal func valueFields(_ selfMirror: Mirror) -> [AnyFieldConnector] {
        selfMirror.children
            .compactMap { $0.value as? AnyFieldConnector }
    }
    
    internal func childrenFields(_ selfMirror: Mirror) -> [AnyChildrenConnector] {
        selfMirror.children
            .compactMap { $0.value as? AnyChildrenConnector }
    }
    
    internal func enumFields(_ selfMirror: Mirror) -> [AnyEnumConnector] {
        selfMirror.children
            .compactMap { $0.value as? AnyEnumConnector }
    }
    
    internal func decodeFields(
        from container: KeyedDecodingContainer<FieldCodingKey>
    ) throws {
        try Mirror(reflecting: self).children.forEach {
            if let decodable = $0.value as? DecodableField {
                try decodable.decodeValue($0.label!, from: container)
            }
        }
    }
}
