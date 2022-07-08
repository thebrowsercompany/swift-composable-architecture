import ComposableArchitecture
import XCTest

class TaskResultTests: XCTestCase {
  func testEqualityNonEquatableError() {
    struct Failure: Error {
      let message: String
    }

    XCTExpectFailure {
      XCTAssertNotEqual(
        TaskResult<Never>.failure(Failure(message: "Something went wrong")),
        TaskResult<Never>.failure(Failure(message: "Something went wrong"))
      )
    } issueMatcher: {
      $0.compactDescription == """
        Tried to compare a non-equatable error type: Failure
        """
    }
  }

  func testEquality_EquatableError() {
    enum Failure: Error, Equatable {
      case message(String)
      case other
    }

    XCTAssertEqual(
      TaskResult<Never>.failure(Failure.message("Something went wrong")),
      TaskResult<Never>.failure(Failure.message("Something went wrong"))
    )
    XCTAssertNotEqual(
      TaskResult<Never>.failure(Failure.message("Something went wrong")),
      TaskResult<Never>.failure(Failure.message("Something else went wrong"))
    )
    XCTAssertEqual(
      TaskResult<Never>.failure(Failure.other),
      TaskResult<Never>.failure(Failure.other)
    )
    XCTAssertNotEqual(
      TaskResult<Never>.failure(Failure.other),
      TaskResult<Never>.failure(Failure.message("Uh oh"))
    )
  }

  func testHashable_HashableError() {
    enum Failure: Error, Hashable {
      case message(String)
      case other
    }

    let error1 = TaskResult<Int>.failure(Failure.message("Something went wrong"))
    let error2 = TaskResult<Int>.failure(Failure.message("Something else went wrong"))
    let statusByError = Dictionary(
      [
        (error1, 1),
        (error2, 2),
        (.failure(Failure.other), 3),
      ],
      uniquingKeysWith: { $1 }
    )

    XCTAssertEqual(Set(statusByError.values), [1, 2, 3])
    XCTAssertNotEqual(error1.hashValue, error2.hashValue)
  }
}
