import Foundation
import Fluent

protocol AnyFieldConnector {
    func set(on model: AnyModel) throws
}

@propertyWrapper
public final class FieldConnector<Model, Value>: AnyFieldConnector
    where Model: CorvusModel, Value: Codable
{
    
    enum Key {
        case required(KeyPath<Model, Model.Field<Value>>)
        case optional(KeyPath<Model, Model.OptionalField<Value>>)
    }
    
    public var wrappedValue: Value {
        get {
            guard let value = self.value else {
                fatalError("Cannot access field before it is initialized")
            }
            return value
        }
        set {
            self.value = newValue
        }
    }
    
    public var value: Value?
    
    let fieldKey: Key
    
    let transform: ((Value) throws -> Value)?
    
    public init(to key: KeyPath<Model, Model.Field<Value>>, transform: ((Value) throws -> Value)? = nil) {
        self.fieldKey = .required(key)
        self.transform = transform
    }

    public init(to key: KeyPath<Model, Model.OptionalField<Value>>, transform: ((Value) throws -> Value)? = nil) {
        self.fieldKey = .optional(key)
        self.transform = transform
    }
}

extension FieldConnector: DecodableField {
    internal func decodeValue(_ key: String, from container: Container) throws {
        if let value = try container.decodeIfPresent(
            Value.self,
            forKey: .init(key)
        ) {
            wrappedValue = value
        }
    }
}

extension FieldConnector {
    func set(on model: AnyModel) throws {
        guard
            let item = model as? Model
        else {
            fatalError(
            """
            cannot set value on model of
            type \(model.self), expected \(Model.self)
            """
            )
        }
        
        let value = transform != nil ? try transform!(wrappedValue) : wrappedValue
        
        switch fieldKey {
        case .optional(let key):
            item[keyPath: key].wrappedValue = value
        case .required(let key):
            item[keyPath: key].wrappedValue = value
        }
    }
}
