extension AsyncSequence {
    public func withWeak<T: AnyObject>(
        _ object: T?
    ) -> WeakAsyncSequence<Element, T> {
        WeakAsyncSequence(
            createAsyncIterator: {
                var iterator = self.makeAsyncIterator()
                return { try await iterator.next() }
            },
            getObject: { [weak object] in
                object
            }
        )
    }
}
