#if canImport(Combine)
import Combine
#elseif canImport(OpenCombine)
import OpenCombine
#endif

extension Effect {
  /// Creates an effect from a Combine publisher.
  ///
  /// - Parameter createPublisher: The closure to execute when the effect is performed.
  /// - Returns: An effect wrapping a Combine publisher.
  public static func publisher<P: Publisher>(
    _ createPublisher: @escaping () -> P,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> Self
  where P.Output == Action, P.Failure == Never {
    ._publisher(registerFingerprint: true, createPublisher, fileID: fileID, line: line)
  }

  static func _publisher<P: Publisher>(
    registerFingerprint: Bool = true,
    _ createPublisher: @escaping () -> P,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> Self
  where P.Output == Action, P.Failure == Never {
    #if DEBUG
    let fingerprints: [Fingerprint]
    let removeFingerprint: () -> Void
    if registerFingerprint {
      let fingerprint = _fingerprintsLock.sync {
        _fingerprints.addFingerprint(fileID: fileID, line: line)
      }
      fingerprints = [fingerprint]
      removeFingerprint = {
        _fingerprintsLock.sync {
          _fingerprints.removeFingerprint(id: fingerprint.id)
        }
      }
    } else {
      fingerprints = []
      removeFingerprint = {}
    }
    #else
    let fingerprints: Void
    #endif
    return Self(
      operation: .publisher(
        withEscapedDependencies { continuation in
          let deferred = Deferred {
            continuation.yield {
              createPublisher()
            }
          }
          #if DEBUG
          return deferred
            .handleEvents(
              receiveCompletion: { _ in removeFingerprint() },
              receiveCancel: removeFingerprint
            )
            .eraseToAnyPublisher()
          #else
          return deferred.eraseToAnyPublisher()
          #endif
        }
      ),
      fingerprints: fingerprints
    )
  }
}

public struct _EffectPublisher<Action>: Publisher {
  public typealias Output = Action
  public typealias Failure = Never

  let effect: Effect<Action>

  public init(_ effect: Effect<Action>) {
    self.effect = effect
  }

  public func receive<S: CombineSubscriber>(
    subscriber: S
  ) where S.Input == Action, S.Failure == Failure {
    self.publisher.subscribe(subscriber)
  }

  private var publisher: AnyPublisher<Action, Failure> {
    switch self.effect.operation {
    case .none:
      return Empty().eraseToAnyPublisher()
    case let .publisher(publisher):
      return publisher
    case let .run(priority, operation):
      return .create { subscriber in
        let task = Task(priority: priority) { @MainActor in
          defer { subscriber.send(completion: .finished) }
          await operation(Send { subscriber.send($0) })
        }
        return AnyCancellable {
          task.cancel()
        }
      }
    }
  }
}
