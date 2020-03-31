import Vapor

public protocol CorvusResponse: Content {
    associatedtype Item
    init(item: Item)
}
