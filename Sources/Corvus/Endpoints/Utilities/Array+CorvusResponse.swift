/// Allows ResponseModifier to work with Arrays of `CorvusResponse`
///
/// Instead of returning a single `CorvusResponse` an array of `CorvusResponse`
/// can be returned instead.
extension Array: CorvusResponse where Element: CorvusResponse {
    public init(item: [Element.Item]) {
        self = item.map { Element(item: $0) }
    }
}
