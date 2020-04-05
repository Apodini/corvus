import Foundation
import Fluent

protocol AnyChildrenConnector {
    func relationFactory(
        for model: AnyModel) throws -> (Database
    ) -> EventLoopFuture<Void>
}

@propertyWrapper
public final class ChildrenDTOConnector<Model, Value>: AnyChildrenConnector
    where Model: CorvusModel, Value: CreateDTO
{
    public var wrappedValue: [Value] {
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
    
    public var value: [Value]?
    
    let childrenKey: KeyPath<Model, Model.Children<Value.Element>>?
    
    public init(to key: KeyPath<Model, Model.Children<Value.Element>>) {
        self.childrenKey = key
    }
}

extension ChildrenDTOConnector: DecodableField {
    internal func decodeValue(_ key: String, from container: Container) throws {
        if let value = try container.decodeIfPresent(
            [Value].self,
            forKey: .init(key)
        ) {
            wrappedValue = value
        }
    }
}

extension ChildrenDTOConnector {
    func relationFactory(
        for model: AnyModel
    ) throws -> (Database) -> EventLoopFuture<Void> {
        guard
            let unwrappedKey = childrenKey,
            let item = model as? Model
        else {
            fatalError(
                """
                cannot generate relation factory without
                childrenKey and item of type \(Model.self)
                """
            )
        }
        
        let children = try wrappedValue.map { try $0.model(selfMirror: Mirror(reflecting: $0)) }
        let childrenField = item[keyPath: unwrappedKey]
        
        return { childrenField.create(children, on: $0) }
    }
}


@propertyWrapper
public final class ChildrenConnector<ModelType, Value>: AnyChildrenConnector
    where ModelType: CorvusModel, Value: Model
{
    public var wrappedValue: [Value] {
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
    
    public var value: [Value]?
    
    let childrenKey: KeyPath<ModelType, ModelType.Children<Value>>?
    
    public init(to key: KeyPath<ModelType, ModelType.Children<Value>>) {
        self.childrenKey = key
    }
}

extension ChildrenConnector: DecodableField {
    internal func decodeValue(_ key: String, from container: Container) throws {
        if let value = try container.decodeIfPresent(
            [Value].self,
            forKey: .init(key)
        ) {
            wrappedValue = value
        }
    }
}

extension ChildrenConnector {
    func relationFactory(
        for model: AnyModel
    ) throws -> (Database) -> EventLoopFuture<Void> {
        guard
            let unwrappedKey = childrenKey,
            let item = model as? ModelType
        else {
            fatalError(
                """
                cannot generate relation factory without
                childrenKey and item of type \(ModelType.self)
                """
            )
        }

        let childrenField = item[keyPath: unwrappedKey]
        return { childrenField.create(self.wrappedValue, on: $0) }
    }
}
