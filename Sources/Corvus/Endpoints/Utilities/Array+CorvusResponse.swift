/// Allows ResponseModifier to work with Arrays of `CorvusResponse`
///
/// Instead of returning a single `CorvusResponse` an array of `CorvusResponse`
/// can be returned instead.
extension Array: CorvusResponse where Element: CorvusResponse {
    
    /// Initializes a `CorvusResponse` which is an `Array` by initializing its
    /// children.
    /// - Parameter item: The values of the items in the `Array`.
    public init(item: [Element.Item]) {
        self = item.map { Element(item: $0) }
    }
}
