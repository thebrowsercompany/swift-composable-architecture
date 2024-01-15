#if DEBUG

@_spi(Internals) import ComposableArchitecture
import XCTest

@MainActor
final class EffectFingerprintingTests: BaseTCATestCase {

  override func tearDown() {
    _fingerprintsLock.sync {
      XCTAssertEqual(_fingerprints.count, 0)
      _fingerprints.removeAll()
    }
  }

  private func assertFingerprintsCount(is count: Int, line: UInt = #line) {
    _fingerprintsLock.sync {
      XCTAssertEqual(_fingerprints.count, count, line: line)
    }
  }

  func testEffectCancellation() async {
    let store = TestStoreOf<TestReducer>(
      initialState: TestReducer.State(),
      reducer: { TestReducer() }
    )
    
    let cancelID = TestReducer.CancelID(rawValue: "cancellation")
    
    await store.send(.effect(cancelID: cancelID))
    assertFingerprintsCount(is: 1)
    await store.send(.effect(cancelID: cancelID))
    assertFingerprintsCount(is: 1)
    await store.send(.effect(cancelID: cancelID))
    assertFingerprintsCount(is: 1)

    await store.send(.cancel(id: cancelID))
    assertFingerprintsCount(is: 0)

    await store.finish()
  }

  func testEffectDebounce() async {
    let mainQueue = DispatchQueue.test
    let store = TestStoreOf<TestReducer>(
      initialState: TestReducer.State(),
      reducer: { TestReducer() },
      withDependencies: {
        $0.mainQueue = mainQueue.eraseToAnyScheduler()
      }
    )
    
    let cancelID = TestReducer.CancelID(rawValue: "debounce")

    await store.send(.debounced(cancelID: cancelID))
    assertFingerprintsCount(is: 1)
    await mainQueue.advance(by: .seconds(2))
    assertFingerprintsCount(is: 0)

    await store.send(.debounced(cancelID: cancelID))
    assertFingerprintsCount(is: 1)
    await store.send(.debounced(cancelID: cancelID))
    assertFingerprintsCount(is: 1)
    await mainQueue.advance(by: .seconds(1))
    assertFingerprintsCount(is: 0)

    await store.send(.debounced(cancelID: cancelID))
    assertFingerprintsCount(is: 1)
    await store.send(.cancel(id: cancelID))
    assertFingerprintsCount(is: 0)
    await store.finish()
  }

  struct TestReducer: Reducer {
    struct State: Equatable { }
    enum Action: Equatable {
      case effect(cancelID: CancelID)
      case debounced(cancelID: CancelID)
      case cancel(id: CancelID)
    }

    struct CancelID: Hashable {
      var rawValue: String
    }

    @Dependency(\.mainQueue) var mainQueue

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {
      case let .effect(cancelID):
        return .run { _ in
          while !Task.isCancelled {
            await Task.yield()
          }
        }
        .cancellable(id: cancelID, cancelInFlight: true)
      case let .debounced(cancelID):
        return .run { _ in }
          .debounce(id: cancelID, for: .seconds(1), scheduler: mainQueue)
      case let .cancel(cancelID):
        return .cancel(id: cancelID)
      }
    }
  }
}

#endif
