extension Optional where Wrapped: AnyObject {
    public func weak<T: AsyncSequence>(
        _ keyPath: KeyPath<Wrapped, T>
    ) throws -> WeakAsyncSequence<T, Wrapped> {
        try map { $0[keyPath: keyPath].withWeak($0) }
            ?? { throw ObjectNilError() }()
    }

    public func weak<T: AsyncSequence>(
        getter: (Wrapped) -> T
    ) throws -> WeakAsyncSequence<T, Wrapped> {
        try map { getter($0).withWeak($0) }
            ?? { throw ObjectNilError() }()
    }
}
