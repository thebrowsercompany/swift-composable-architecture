import Foundation

// self incrementing ID for easier debugging
public struct DirtyCheckingID: Hashable {
    static var counter: UInt64 = 0
    var value: UInt64

    init() {
        value = Self.counter
        Self.counter += 1
    }
}

@propertyWrapper public struct DirtyChecked<Value> {
    public let id = DirtyCheckingID()
    public var lastUpdatedIteration: UInt64 = 0

    var _wrappedValue: Value {
        didSet {
            lastUpdatedIteration = DirtyCounter.iteration
        }
    }

    public var wrappedValue: Value {
        get {
            Memoizer.shared.record(id, lastUpdate: lastUpdatedIteration)
            return _wrappedValue
        }
        set {
            _wrappedValue = newValue
        }
    }

    /// Accesses child property without registering self for dirty access
    /// Which means we can decide to filter down update triggers for the memoized blocks e.g. only child change will trigger updates
    public func accessChild<Something>(for keyPath: KeyPath<Value, DirtyChecked<Something>>) -> DirtyChecked<Something> {
        _wrappedValue[keyPath: keyPath]
    }

    public var projectedValue: Self { self }

    public init(wrappedValue: Value) {
        self._wrappedValue = wrappedValue
    }
}

extension DirtyChecked: Equatable where Value: Equatable {
}
