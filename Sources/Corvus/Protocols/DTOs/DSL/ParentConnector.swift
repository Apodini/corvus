import Foundation
import Fluent

@propertyWrapper
public final class ParentConnector<Model, Value>: AnyFieldConnector
    where Model: CorvusModel, Value: CorvusModel
{

    public typealias FieldKey = KeyPath<Model, Model.Parent<Value>>
    public typealias OptionalFieldKey = KeyPath<Model, Model.OptionalParent<Value>>
    
    enum Key {
        case required(FieldKey)
        case optional(OptionalFieldKey)
    }
    
    public var wrappedValue: Value.IDValue {
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
    
    public var value: Value.IDValue?
    
    let fieldKey: Key
    
    public init(to key: FieldKey) {
        self.fieldKey = .required(key)
    }

    public init(to key: OptionalFieldKey) {
        self.fieldKey = .optional(key)
    }
}

extension ParentConnector: DecodableField {
    internal func decodeValue(_ key: String, from container: Container) throws {
        if let value = try container.decodeIfPresent(
            Value.IDValue.self,
            forKey: .init(key)
        ) {
            wrappedValue = value
        }
    }
}

extension ParentConnector {
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
        
        switch fieldKey {
        case .optional(let key):
            item[keyPath: key].id = wrappedValue
        case .required(let key):
            item[keyPath: key].id = wrappedValue
        }
        
    }
}
