import Foundation
import Fluent

protocol AnyEnumConnector {
    func set(on model: AnyModel)
}

@propertyWrapper
public final class EnumConnector<Model, Value>: AnyEnumConnector
    where Model: CorvusModel, Value: Codable & RawRepresentable, Value.RawValue == String
{
 
    public typealias FieldKey = KeyPath<Model, Model.Enum<Value>>
    public typealias OptionalFieldKey = KeyPath<Model, Model.OptionalEnum<Value>>
    
    enum Key {
        case required(FieldKey)
        case optional(OptionalFieldKey)
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
    
    public init(to key: FieldKey) {
        self.fieldKey = .required(key)
    }

    public init(to key: OptionalFieldKey) {
        self.fieldKey = .optional(key)
    }
}

extension EnumConnector: DecodableField {
    internal func decodeValue(_ key: String, from container: Container) throws {
        if let value = try container.decodeIfPresent(
            Value.self,
            forKey: .init(key)
        ) {
            wrappedValue = value
        }
    }
}

extension EnumConnector {
    func set(on model: AnyModel) {
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
        
        switch fieldKey {
        case .optional(let key):
            item[keyPath: key].wrappedValue = wrappedValue
        case .required(let key):
            item[keyPath: key].wrappedValue = wrappedValue
        }
    }
}
