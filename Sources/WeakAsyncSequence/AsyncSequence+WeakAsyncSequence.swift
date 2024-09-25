extension AsyncSequence {
    public func withWeak<T: AnyObject>(
        _ object: T?
    ) -> WeakAsyncSequence<Self, T> {
        WeakAsyncSequence(sequence: self) { [weak object] in
            object
        }
    }
}
