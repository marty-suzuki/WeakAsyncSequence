public struct WeakAsyncSequence<Value, Object>: AsyncSequence {
    public typealias Element = (Value, Object)

    internal let createAsyncIterator: () -> () async throws -> Value?
    internal let getObject: () -> Object?

    public func makeAsyncIterator() -> Iterator {
        Iterator(
            getNext: createAsyncIterator(),
            getObject: getObject
        )
    }

    public struct Iterator: AsyncIteratorProtocol {
        internal let getNext: () async throws -> Value?
        internal let getObject: () -> Object?

        mutating public func next() async throws -> Element? {
            guard
                let element = try await getNext(),
                let object = getObject()
            else {
                return nil
            }
            return (element, object)
        }
    }
}
