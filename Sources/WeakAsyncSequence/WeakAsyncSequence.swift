public struct WeakAsyncSequence<Sequence: AsyncSequence, Object>: AsyncSequence {
    public typealias Element = (Sequence.Element, Object)

    internal let sequence: Sequence
    internal let getObject: () -> Object?

    public func makeAsyncIterator() -> Iterator {
        Iterator(
            iterator: sequence.makeAsyncIterator(),
            getObject: getObject
        )
    }

    public struct Iterator: AsyncIteratorProtocol {
        internal var iterator: Sequence.AsyncIterator
        internal let getObject: () -> Object?

        mutating public func next() async throws -> Element? {
            guard
                let element = try await iterator.next(),
                let object = getObject()
            else {
                return nil
            }
            return (element, object)
        }
    }
}
