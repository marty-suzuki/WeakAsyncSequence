# WeakAsyncSequence
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/treastrain/AsyncSequenceSubscription/blob/main/LICENSE)
![Swift: 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)
![Platform: iOS|iPadOS|macOS|tvOS|watchOS|visionOS](https://img.shields.io/badge/Platform-iOS%20%7C%20iPadOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-lightgrey.svg)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

**WeakAsyncSequence** avoids implicit reference type capturing when using a for-in loop with an AsyncSequence.

**Without WeakAsyncSequence 👻**

```swift
let stream: AsyncStream<Int> = ...

func doSomething() { ... }

let task = Task { [weak self] in
    guard let self else { return }

    for await i in stream { // Capturing self and it might be caused memory leaks.
        doSomething()
    }
}
```

**With WeakAsyncSequence ✅**

```swift
let stream: AsyncStream<Int> = ...

func doSomething() { ... }

let task = Task { [weak self] in
    for try await (i, `self`) in try self.weak(\.stream) { // Receives Element and self without memory leaks.
        self.doSomething()
    }
}
```

## Installation

Simply add the following line to your `Package.swift`:
```
.package(url: "https://github.com/marty-suzuki/WeakAsyncSequence.git", from: "0.1.0")
```

## What is implicit reference type capturing with AsyncSequence for-in syntax?

This is a case of a memory leak.

```swift
final class Leaks: Sendable {
    private let asyncStream = AsyncStream<Int> { continuation in
        Task {
            for i in 1...10 {
                continuation.yield(i)
                try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
            }
            continuation.finish()
        }
    }

    private let spy: Spy

    init(_ spy: Spy) {
        self.spy = spy
        spy.add("init")
    }

    deinit {
        spy.add("deinit")
    }

    func doTask() {
        Task { [weak self, spy] in
            guard let self else {
                return
            }

            for try await i in asyncStream {
                spy.add("i = \(i) with \(self)")
            }
        }
    }
}

@Test func leaksAndNotCalledDeinit() async throws {
    let spy = Spy()
    var object: Leaks? = Leaks(spy)
    let name = "\(object!)"

    object?.doTask()
    try await Task.sleep(nanoseconds: 3 * NSEC_PER_SEC)
    object = nil

    let expected = [
        "init",
        "i = 1 with \(name)",
        "i = 2 with \(name)",
        "i = 3 with \(name)",
        // The deinit was not called, therefore it means a memory leak occurred.
    ]
    #expect(spy.values == expected)
}
```

This is a case of no memory leaks.

```swift
final class NoLeaks: Sendable {
    private let asyncStream = AsyncStream<Int> { continuation in
        Task {
            for i in 1...10 {
                continuation.yield(i)
                try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
            }
            continuation.finish()
        }
    }

    private let spy: Spy

    init(_ spy: Spy) {
        self.spy = spy
        spy.add("init")
    }

    deinit {
        spy.add("deinit")
    }

    func doTask() {
        Task { [weak self, spy] in
            for try await (i, `self`) in try self.weak(\.asyncStream) {
                spy.add("i = \(i) with \(self)")
            }
        }
    }
}

@Test func noLeaksAndCalledDeinit() async throws {
    let spy = Spy()
    var object: NoLeaks? = NoLeaks(spy)
    let name = "\(object!)"

    object?.doTask()
    try await Task.sleep(nanoseconds: 3 * NSEC_PER_SEC)
    object = nil

    let expected = [
        "init",
        "i = 1 with \(name)",
        "i = 2 with \(name)",
        "i = 3 with \(name)",
        "deinit",
    ]
    #expect(spy.values == expected)
}
```