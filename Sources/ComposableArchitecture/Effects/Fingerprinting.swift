#if DEBUG
import Foundation

@usableFromInline
struct Fingerprint {
  let id: UUID
  let fileID: StaticString
  let line: UInt
}

@_spi(Internals) public let _fingerprints = _FingerprintsCollection()
@_spi(Internals) public let _fingerprintsLock = NSRecursiveLock()

@_spi(Internals)
public final class _FingerprintsCollection {
  struct CancelID: Hashable {
    let discriminator: ObjectIdentifier
    let id: AnyHashable

    init<ID: Hashable>(id: ID) {
      self.discriminator = ObjectIdentifier(type(of: id))
      self.id = AnyHashable(id)
    }
  }

  var storage: [UUID: Fingerprint] = [:]
  var fingerprintIDsByCancelID: [CancelID: Set<UUID>] = [:]

  func addFingerprint(fileID: StaticString, line: UInt) -> Fingerprint {
    let fingerprint = Fingerprint(id: UUID(), fileID: fileID, line: line)
    self.storage[fingerprint.id] = fingerprint
    return fingerprint
  }

  func removeFingerprint(id: UUID) {
    self.storage.removeValue(forKey: id)
  }

  func registerFingerprintIDs<ID: Hashable, C: Collection>(
    _ fingerprintIDs: C,
    forCancelID id: ID
  )
  where C.Element == UUID
  {
    self.fingerprintIDsByCancelID[CancelID(id: id), default: []].formUnion(fingerprintIDs)
  }

  func removeFingerprintIDs<ID: Hashable, C: Collection>(
    _ fingerprintIDs: C,
    forCancelID id: ID
  ) 
  where C.Element == UUID
  {
    let cancelID = CancelID(id: id)
    guard var allFingerprintIDs = self.fingerprintIDsByCancelID.removeValue(forKey: cancelID) else { return }
    allFingerprintIDs.subtract(fingerprintIDs)
    fingerprintIDs.forEach(self.removeFingerprint(id:))
    guard !allFingerprintIDs.isEmpty else { return }
    self.fingerprintIDsByCancelID[cancelID] = allFingerprintIDs
  }

  @discardableResult
  func removeAllFingerprintIDs<ID: Hashable>(forCancelID id: ID) -> Set<UUID>? {
    let cancelID = CancelID(id: id)
    guard var fingerprintIDs = self.fingerprintIDsByCancelID.removeValue(forKey: cancelID) else { return nil }
    fingerprintIDs.forEach(self.removeFingerprint(id:))
    return fingerprintIDs
  }

  @usableFromInline
  func filter<S: Sequence>(fingerprints: S) -> [Fingerprint] where S.Element == Fingerprint {
    fingerprints.filter({ self.storage[$0.id] != nil })
  }

  public var count: Int {
    self.storage.count
  }

  public func removeAll() {
    self.storage.removeAll()
  }
}

#endif
