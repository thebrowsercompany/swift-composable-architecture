#if DEBUG
  #if canImport(Combine)
import Combine
#elseif canImport(OpenCombine)
import OpenCombine
#endif
  import XCTest

  @testable import ComposableArchitecture

  @MainActor
  final class StoreFilterTests: BaseTCATestCase {
    var cancellables: Set<AnyCancellable> = []

    func testFilter() async {
      let store = Store<Int?, Void>(initialState: nil) {}
        .invalidate { $0 != nil }

      let viewStore = ViewStore(store, observe: { $0 })
      var count = 0
      viewStore.publisher
        .sink { _ in count += 1 }
        .store(in: &self.cancellables)

      XCTAssertEqual(count, 1)
      viewStore.send(())
      XCTAssertEqual(count, 1)
      viewStore.send(())
      XCTAssertEqual(count, 1)
    }
  }
#endif
