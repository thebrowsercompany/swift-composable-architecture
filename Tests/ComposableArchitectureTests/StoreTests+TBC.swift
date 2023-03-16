import Combine
@_spi(Internals) import ComposableArchitecture
import XCTest

// TBC additions
extension StoreTests {
    func testScopingRemovesDuplicatesWithProvidedClosure() {
        struct State: Equatable {
          var place: String
        }
        enum Action: Equatable {
          case noop
          case updatePlace(String)
        }
        let parentStore = Store<State, Action>(
          initialState: .init(place: "New York"),
          reducer: Reduce { state, action in
              switch action {
              case .noop:
                return .none
              case let .updatePlace(place):
                state.place = place
                return .none
              }
            }
        )
        let childStore: Store<State, Action> = parentStore.scope(
          state: { $0 },
          action: { $0 },
          removeDuplicates: ==
        )
        var scopeCount: Int = 0
        let leafStore: Store<State, Action> = childStore.scope(
          state: { parentState -> State in
            scopeCount += 1
            return parentState
          },
          action: { $0 },
          removeDuplicates: ==
        )
        XCTAssertEqual(scopeCount, 1)
        _ = parentStore.send(.noop)
        XCTAssertEqual(scopeCount, 1)
        _ = parentStore.send(.updatePlace("Washington"))
        XCTAssertEqual(scopeCount, 2)
        _ = childStore.send(.noop)
        _ = leafStore.send(.noop)
      }

    func testSyncActions() {
        if #available(macOS 12.0, *) {
            struct State: Equatable {
                var name: String
            }

            enum Action: Equatable {
                case setup
                case teardown
                case updateFromView(String)
                case subscription(String)
            }

            struct TestClient {
                var sendUpdate: (String) -> Void
                var updates: () -> AsyncStream<String>
            }

            let passthroughSubject = PassthroughSubject<String, Never>()
            let client = TestClient(
                sendUpdate: {
                    passthroughSubject.send($0)
                },
                updates: {
                    passthroughSubject.values.eraseToStream()
                }
            )

            enum CancellationToken: Hashable {}

            let store = Store<State, Action>(
                initialState: .init(name: "BCNY"),
                reducer: Reduce { state, action in
                    switch action {
                    case .setup:
                        return .run { send in
                            for await update in client.updates() {
                                await send(.subscription(update))
                            }
                        }
                        .cancellable(id: CancellationToken.self, cancelInFlight: true)
                    case let .subscription(value):
                        state.name = value
                        return .none
                    case let .updateFromView(update):
                        return .fireAndForget {
                            client.sendUpdate(update)
                        }
                    case .teardown:
                        return .cancel(id: CancellationToken.self)
                    }
                }
            )

            let expectation = XCTestExpectation(description: "Run update after subscription has started")

            let viewStore = ViewStore(store)
            viewStore.send(.setup)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                viewStore.send(.updateFromView("BCNY_2"))
                XCTAssertEqual(viewStore.state.name, "BCNY_2")
                expectation.fulfill()
                viewStore.send(.teardown)
            }
            wait(for: [expectation], timeout: 5)
        }
    }
}
