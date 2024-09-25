import Foundation
import Testing
@testable import WeakAsyncSequence

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
    ]
    #expect(spy.values == expected)
}

private final class NoLeaks: Sendable {
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

private final class Leaks: Sendable {
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

private final class Spy: @unchecked Sendable {
    private(set) var values: [String] = []

    func add(_ value: String) {
        values.append(value)
    }
}
