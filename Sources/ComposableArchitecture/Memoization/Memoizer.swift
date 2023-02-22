import Foundation

public protocol MemoizableState {
    func lastUpdate(for id: DirtyCheckingID) -> UInt64
}

public typealias ScopeID = String

public class Memoizer: ObservableObject {
    @Published
    public var hotScopes = Set<ScopeID>()

    struct DirtyPair: Hashable {
        var id: DirtyCheckingID
        var lastUpdate: UInt64
    }

    class Scope: Identifiable, Hashable {
        var id: ScopeID
        var lastUpdateCounter: UInt64
        var keyPaths: Set<DirtyPair>
        var lastValue: Any!

        /// Scopes this memoization depends
        /// e.g. E = C + B will mean that C,B are `sourceScopes`
        var sourceScopes: Set<Scope>

        /// The destination scope
        /// e.g. E = C + B will mean that C,B have `parentScope` set to E
        var derivedScope: Scope?

        var allKeyPaths: Set<DirtyPair> {
            Set(sourceScopes.flatMap { Array($0.allKeyPaths) } + keyPaths)
        }

        init(id: ScopeID) {
            self.id = id
            self.lastUpdateCounter = 0
            self.keyPaths = []
            self.lastValue = nil
            self.sourceScopes = []
        }

        // we only care about id for this
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        static func == (lhs: Memoizer.Scope, rhs: Memoizer.Scope) -> Bool {
            lhs.id == rhs.id
        }
    }

    var scopes = [ScopeID: Scope]()
    private var activeScopes = [Scope]()

    public static var shared: Memoizer = .init()

    public func record(_ id: DirtyCheckingID, lastUpdate: UInt64) {
        guard let activeScope = activeScopes.last else {
            return
        }
        activeScope.keyPaths.insert(.init(id: id, lastUpdate: lastUpdate))
    }

    public func reduce<State>(_ state: inout State, _ reduce: (inout State) -> Void) {
        reduce(&state)
    }

    public struct MemoizationResult<Value> {
        var value: Value
        var updated: Bool
    }
    /// Only calls reducer logic if there are no recorded dependencies or any of them have changed
    /// - Parameters:
    ///   - state: State to evaluate for equality checks
    ///   - scopeID: scopeID to use, useful for tests
    ///   - memoize: memoization function
    /// - Returns: The last value for the given memoization scope
    @discardableResult public func memoized<State: MemoizableState, Value>(state: State, scopeID: ScopeID, memoize: (State) -> Value) -> MemoizationResult<Value> {
        func updateScope(scope: Scope, with value: Value) {
            scopes[scopeID] = scope
            scope.lastValue = value
            scope.lastUpdateCounter = DirtyCounter.iteration

            // mark parent scope as needing to run
            scope.derivedScope?.lastUpdateCounter = 0

            var scopes = activeScopes
            var derived: Scope? = scopes.popLast()
            while derived != nil {
                derived?.sourceScopes.insert(scope)
                scope.derivedScope = derived
                derived = scopes.popLast()
            }
        }

        guard let scope = scopes[scopeID] else {
            activeScopes.append(.init(id: scopeID))
            hotScopes.insert(scopeID)
            let value = memoize(state)
            updateScope(scope: activeScopes.removeLast(), with: value)
            return .init(value: value, updated: true)
        }

        // Same mutation run, no need to re-execute scope
        if scope.lastUpdateCounter == DirtyCounter.iteration {
            // add source scope
            activeScopes.last?.sourceScopes.insert(scope)
            scope.derivedScope = activeScopes.last
            return .init(value: scope.lastValue as! Value, updated: false)

        }

        // if there is ANY change we need to run reduce again
        let needsToRun = scope.lastUpdateCounter == 0 || scope.allKeyPaths.contains(where: { config in
            return state.lastUpdate(for: config.id) > config.lastUpdate
        })

        if needsToRun {
            hotScopes.insert(scopeID)
            activeScopes.append(scope)

            // reset tracking for the given cache refresh
            scope.keyPaths.removeAll()

            let value = memoize(state)
            _ = activeScopes.removeLast()
            updateScope(scope: scope, with: value)
            return .init(value: value, updated: true)
        }

        return .init(value: scope.lastValue as! Value, updated: false)
    }

    public func propertyIds(for scope: ScopeID) -> [DirtyCheckingID] {
        scopes[scope]?.allKeyPaths.map(\.id) ?? []
    }

    public func sourceScopes(for scope: ScopeID) -> [ScopeID] {
        scopes[scope]?.sourceScopes.flatMap { source in
            var sources = sourceScopes(for: source.id)
            sources.append(source.id)
            return sources
        } ?? []
    }
}
