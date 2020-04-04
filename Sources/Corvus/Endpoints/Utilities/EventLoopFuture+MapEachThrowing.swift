import NIO

/// An extension to `EventLoopFuture` to map over a sequence with a throwing
/// function signature.
extension EventLoopFuture where Value: Sequence {

    /// Allows the transformation of an array of `EventLoopFuture` values
    /// through some closure with a throwing signature.
    ///
    /// - Parameter transform: The closure to transform the futures by.
    /// - Returns: A new `EventLoopFuture` containing the transformed results.
    func mapEachThrowing<Result>(
        _ transform: @escaping (_ element: Value.Element) throws -> Result
    ) -> EventLoopFuture<[Result]> {
        self.flatMapThrowing { sequence in
            try sequence.map(transform)
        }
    }
}
