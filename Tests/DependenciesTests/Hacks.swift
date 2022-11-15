import Foundation

#if os(Windows)
struct XCTIssue {
  var compactDescription: String { "" }
}

func XCTExpectFailure(
  _ failureReason: String? = nil, enabled: Bool? = nil, strict: Bool? = nil,
  issueMatcher: ((XCTIssue) -> Bool)? = nil
) {

}

func XCTExpectFailure<R>(
  _ failureReason: String? = nil, enabled: Bool? = nil, strict: Bool? = nil,
  failingBlock: () throws -> R, issueMatcher: ((XCTIssue) -> Bool)? = nil
) rethrows -> R {
  try failingBlock()
}
#endif
