//
//  SecretStorageTests.swift
//

import Security
import Synchronization
import XCTest
@testable import MarkEditKit

@MainActor
final class SecretStorageTests: XCTestCase {
  func testCRUDAndLocalProtection() async throws {
    let keychain = MemorySecretKeychain()
    let storage = KeychainSecretStorage(keychain: keychain)
    let missing = try await storage.has(namespace: "first", key: "token")
    XCTAssertFalse(missing)

    try await storage.set(namespace: "first", key: "token", value: "secret")
    let exists = try await storage.has(namespace: "first", key: "token")
    XCTAssertTrue(exists)

    let value = try await storage.get(namespace: "first", key: "token")
    XCTAssertEqual(value, "secret")

    try await storage.set(namespace: "first", key: "token", value: "")
    let empty = try await storage.get(namespace: "first", key: "token")
    XCTAssertEqual(empty, "")

    let removed = try await storage.delete(namespace: "first", key: "token")
    XCTAssertTrue(removed)

    let absent = try await storage.delete(namespace: "first", key: "token")
    XCTAssertFalse(absent)

    let deleted = try await storage.get(namespace: "first", key: "token")
    XCTAssertNil(deleted)

    let calls = keychain.state.withLock { $0.calls }
    XCTAssertTrue(calls.allSatisfy { !$0.onMainThread && $0.dataProtection && !$0.synchronizable })
    XCTAssertTrue(calls.allSatisfy { $0.itemClass == kSecClassGenericPassword as String })
    XCTAssertEqual(calls.first { $0.operation == "add" }?.accessibility, kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)
    XCTAssertEqual(calls.filter { $0.operation == "copy" }.map(\.returnsData), [false, false, true, true, true])
  }

  func testNamespacesAndKeysAreIndependent() async throws {
    let storage = KeychainSecretStorage(keychain: MemorySecretKeychain())
    try await storage.set(namespace: "first", key: "token", value: "one")
    try await storage.set(namespace: "second", key: "token", value: "two")
    try await storage.set(namespace: "first", key: "other", value: "three")
    _ = try await storage.delete(namespace: "first", key: "token")

    let second = try await storage.get(namespace: "second", key: "token")
    let other = try await storage.get(namespace: "first", key: "other")
    XCTAssertEqual(second, "two")
    XCTAssertEqual(other, "three")
  }

  func testKeychainErrorsAreNotAbsence() async {
    let keychain = MemorySecretKeychain()
    keychain.state.withLock { $0.failure = errSecInteractionNotAllowed }
    let storage = KeychainSecretStorage(keychain: keychain)
    await expectKeychainError { _ = try await storage.has(namespace: "test", key: "token") }
    await expectKeychainError { _ = try await storage.get(namespace: "test", key: "token") }
    await expectKeychainError { try await storage.set(namespace: "test", key: "token", value: "secret") }
    await expectKeychainError { _ = try await storage.delete(namespace: "test", key: "token") }
  }

  func testDuplicateAddRetriesUpdateWithoutDeleting() async throws {
    let keychain = MemorySecretKeychain()
    keychain.state.withLock { $0.duplicateOnAdd = true }
    let storage = KeychainSecretStorage(keychain: keychain)

    try await storage.set(namespace: "test", key: "token", value: "secret")
    let value = try await storage.get(namespace: "test", key: "token")
    XCTAssertEqual(value, "secret")
    XCTAssertEqual(keychain.state.withLock { $0.calls.map(\.operation) }, ["update", "add", "update", "copy"])
  }

  func testInvalidStoredDataRejects() async throws {
    let keychain = MemorySecretKeychain()
    let storage = KeychainSecretStorage(keychain: keychain)
    try await storage.set(namespace: "test", key: "token", value: "secret")
    keychain.state.withLock { state in
      for key in state.items.keys {
        state.items[key] = Data([0xFF])
      }
    }

    do {
      _ = try await storage.get(namespace: "test", key: "token")
      XCTFail("Expected invalid UTF-8 to reject")
    } catch SecretStorageError.invalidData {
      // Expected.
    }
  }

  func testOnlyGetRequestsApprovalEveryTimeIncludingMissingItems() async throws {
    let keychain = MemorySecretKeychain()
    let delegate = SecretApproval()
    let module = makeModule(delegate: delegate, keychain: keychain)

    _ = await module.has(capability: script.capability, key: "token")
    let stored = await module.set(capability: script.capability, key: "token", value: "secret")
    XCTAssertNil(try response(stored)["error"])
    XCTAssertTrue(delegate.requests.isEmpty)

    let value = await module.get(capability: script.capability, key: "token")
    XCTAssertEqual(try response(value)["value"] as? String, "secret")

    _ = await module.delete(capability: script.capability, key: "token")
    let missing = await module.get(capability: script.capability, key: "token")
    XCTAssertTrue(try response(missing).isEmpty)
    XCTAssertEqual(delegate.requests.map(\.key), ["token", "token"])
    XCTAssertEqual(delegate.requests.map(\.path), [scriptPath, scriptPath])
    XCTAssertEqual(delegate.requests.map(\.extensionID), ["extension", "extension"])
  }

  func testDeniedReadNeverTouchesKeychain() async throws {
    let keychain = MemorySecretKeychain()
    let delegate = SecretApproval()
    delegate.denied = true

    let module = makeModule(delegate: delegate, keychain: keychain)
    let result = await module.get(capability: script.capability, key: "token")
    XCTAssertEqual(try response(result)["error"] as? String, SecretStorageError.cancelled.localizedDescription)
    XCTAssertTrue(keychain.state.withLock { $0.calls.isEmpty })
  }

  func testForgedCapabilitiesRejectEveryOperation() async throws {
    let keychain = MemorySecretKeychain()
    let delegate = SecretApproval()
    let module = makeModule(delegate: delegate, keychain: keychain)
    let otherEditor = EditorModuleSecretStorage.Context(id: script.id, path: script.path)

    for capability in ["", script.id, script.path, UUID().uuidString, otherEditor.capability] {
      let results = [
        await module.has(capability: capability, key: "token"),
        await module.get(capability: capability, key: "token"),
        await module.set(capability: capability, key: "token", value: "secret"),
        await module.delete(capability: capability, key: "token"),
      ]

      for result in results {
        XCTAssertEqual(try response(result)["error"] as? String, SecretStorageError.missingContext.localizedDescription)
      }
    }

    XCTAssertTrue(delegate.requests.isEmpty)
    XCTAssertTrue(keychain.state.withLock { $0.calls.isEmpty })
  }

  func testDifferentWindowsUseSamePersistentNamespace() async throws {
    let keychain = MemorySecretKeychain()
    let delegate = SecretApproval()
    let firstModule = makeModule(delegate: delegate, keychain: keychain)
    let second = EditorModuleSecretStorage.Context(id: script.id, path: "/scripts/renamed.js")
    let secondModule = EditorModuleSecretStorage(
      contexts: [second], delegate: delegate, storage: KeychainSecretStorage(keychain: keychain)
    )

    XCTAssertNotEqual(script.capability, second.capability)
    _ = await firstModule.set(capability: script.capability, key: "token", value: "secret")
    let value = await secondModule.get(capability: second.capability, key: "token")
    XCTAssertEqual(try response(value)["value"] as? String, "secret")
    let rejected = await secondModule.get(capability: script.capability, key: "token")
    XCTAssertEqual(try response(rejected)["error"] as? String, SecretStorageError.missingContext.localizedDescription)
  }

  func testEmptyKeysRejectWithoutTouchingKeychain() async throws {
    let delegate = SecretApproval()
    let keychain = MemorySecretKeychain()
    let module = makeModule(delegate: delegate, keychain: keychain)
    let results = [
      await module.has(capability: script.capability, key: ""),
      await module.get(capability: script.capability, key: ""),
      await module.set(capability: script.capability, key: "", value: "secret"),
      await module.delete(capability: script.capability, key: ""),
    ]

    for result in results {
      XCTAssertEqual(try response(result)["error"] as? String, SecretStorageError.invalidKey.localizedDescription)
    }

    XCTAssertTrue(delegate.requests.isEmpty)
    XCTAssertTrue(keychain.state.withLock { $0.calls.isEmpty })
  }

  func testBridgePropagatesCancellationAndMissingResults() async throws {
    let delegate = SecretApproval()
    let module = makeModule(delegate: delegate, keychain: MemorySecretKeychain())
    let parameters = try JSONEncoder().encode(["capability": script.capability, "key": "token"])
    let missing = await module.bridge.invoke(method: "get", parameters: parameters)
    XCTAssertEqual(try XCTUnwrap(missing).get() as? String, "{}")
    delegate.denied = true

    let denied = await module.bridge.invoke(method: "get", parameters: parameters)
    let json = try XCTUnwrap(try XCTUnwrap(denied).get() as? String)
    XCTAssertEqual(try response(json)["error"] as? String, SecretStorageError.cancelled.localizedDescription)
  }

  func testBridgeDispatchesWritesAndExistenceChecks() async throws {
    let delegate = SecretApproval()
    let module = makeModule(delegate: delegate, keychain: MemorySecretKeychain())
    let writeParameters = try JSONEncoder().encode(["capability": script.capability, "key": "token", "value": "secret"])
    let stored = await module.bridge.invoke(method: "set", parameters: writeParameters)
    XCTAssertEqual(try XCTUnwrap(stored).get() as? String, "{}")

    let parameters = try JSONEncoder().encode([
      "capability": script.capability,
      "key": "token",
    ])

    for method in ["has", "delete"] {
      let result = await module.bridge.invoke(method: method, parameters: parameters)
      let json = try XCTUnwrap(try XCTUnwrap(result).get() as? String)
      XCTAssertEqual(try response(json)["value"] as? Bool, true)
    }

    XCTAssertTrue(delegate.requests.isEmpty)
  }

  func testBridgeRejectsLegacyPathsAndIgnoresClaimedIdentity() async throws {
    let delegate = SecretApproval()
    let keychain = MemorySecretKeychain()
    let victim = EditorModuleSecretStorage.Context(id: "victim", path: "/scripts/victim.js")
    let module = EditorModuleSecretStorage(
      contexts: [script, victim], delegate: delegate, storage: KeychainSecretStorage(keychain: keychain)
    )

    _ = await module.set(capability: victim.capability, key: "token", value: "victim-secret")
    for method in ["has", "get", "set", "delete"] {
      let parameters = try JSONEncoder().encode(["path": victim.path, "key": "token", "value": "forged"])
      let result = await module.bridge.invoke(method: method, parameters: parameters)
      let json = try XCTUnwrap(try XCTUnwrap(result).get() as? String)
      XCTAssertEqual(try response(json)["error"] as? String, SecretStorageError.missingContext.localizedDescription)
    }

    let parameters = try JSONEncoder().encode([
      "capability": script.capability, "path": victim.path, "id": victim.id, "key": "token",
    ])

    let result = await module.bridge.invoke(method: "get", parameters: parameters)
    XCTAssertEqual(try XCTUnwrap(result).get() as? String, "{}")
    XCTAssertEqual(delegate.requests.map(\.extensionID), [script.id])
    let value = await module.get(capability: victim.capability, key: "token")
    XCTAssertEqual(try response(value)["value"] as? String, "victim-secret")
  }

  private let script = EditorModuleSecretStorage.Context(id: "extension", path: "/scripts/extension.js")
  private var scriptPath: String { script.path }

  private func response(_ json: String) throws -> [String: Any] {
    try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
  }

  private func makeModule(
    delegate: SecretApproval,
    keychain: MemorySecretKeychain
  ) -> EditorModuleSecretStorage {
    EditorModuleSecretStorage(contexts: [script], delegate: delegate, storage: KeychainSecretStorage(keychain: keychain))
  }

  private func expectKeychainError(_ operation: () async throws -> Void) async {
    do {
      try await operation()
      XCTFail("Expected Keychain failure")
    } catch SecretStorageError.keychain(let status) {
      XCTAssertEqual(status, errSecInteractionNotAllowed)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}

@MainActor
private final class SecretApproval: EditorModuleSecretStorageDelegate {
  var denied = false
  var requests: [(extensionID: String, path: String, key: String)] = []

  func confirmSecretAccess(extensionID: String, path: String, key: String) async throws {
    requests.append((extensionID, path, key))
    if denied {
      throw SecretStorageError.cancelled
    }
  }
}

private final class MemorySecretKeychain: SecretKeychain {
  struct Item: Hashable {
    let service: String
    let account: String
  }

  struct Call: Sendable {
    let operation: String
    let onMainThread: Bool
    let dataProtection: Bool
    let synchronizable: Bool
    let itemClass: String?
    let accessibility: String?
    let returnsData: Bool

    init(_ operation: String, _ query: [String: Any]) {
      self.operation = operation
      onMainThread = Thread.isMainThread
      dataProtection = query[kSecUseDataProtectionKeychain as String] as? Bool == true
      synchronizable = query[kSecAttrSynchronizable as String] as? Bool == true
      itemClass = query[kSecClass as String] as? String
      accessibility = query[kSecAttrAccessible as String] as? String
      returnsData = query[kSecReturnData as String] as? Bool == true
    }
  }

  struct State {
    var items: [Item: Data] = [:]
    var calls: [Call] = []
    var failure: OSStatus?
    var duplicateOnAdd = false
  }

  let state = Mutex(State())

  func copyMatching(_ query: [String: Any]) -> (OSStatus, Data?) {
    state.withLock {
      $0.calls.append(Call("copy", query))
      if let failure = $0.failure { return (failure, nil) }
      guard let key = item(query), let data = $0.items[key] else { return (errSecItemNotFound, nil) }
      return (errSecSuccess, query[kSecReturnData as String] as? Bool == true ? data : nil)
    }
  }

  func add(_ attributes: [String: Any]) -> OSStatus {
    state.withLock {
      $0.calls.append(Call("add", attributes))
      if let failure = $0.failure { return failure }
      guard let key = item(attributes), let data = attributes[kSecValueData as String] as? Data else {
        return errSecParam
      }

      if $0.duplicateOnAdd {
        $0.duplicateOnAdd = false
        $0.items[key] = Data("competing write".utf8)
        return errSecDuplicateItem
      }

      guard $0.items[key] == nil else {
        return errSecDuplicateItem
      }

      $0.items[key] = data
      return errSecSuccess
    }
  }

  func update(_ query: [String: Any], attributes: [String: Any]) -> OSStatus {
    state.withLock {
      $0.calls.append(Call("update", query))
      if let failure = $0.failure { return failure }
      guard let key = item(query), $0.items[key] != nil else { return errSecItemNotFound }
      guard let data = attributes[kSecValueData as String] as? Data else { return errSecParam }
      $0.items[key] = data
      return errSecSuccess
    }
  }

  func delete(_ query: [String: Any]) -> OSStatus {
    state.withLock {
      $0.calls.append(Call("delete", query))
      if let failure = $0.failure { return failure }
      guard let key = item(query), $0.items.removeValue(forKey: key) != nil else { return errSecItemNotFound }
      return errSecSuccess
    }
  }

  private func item(_ query: [String: Any]) -> Item? {
    guard let service = query[kSecAttrService as String] as? String,
          let account = query[kSecAttrAccount as String] as? String else {
      return nil
    }

    return Item(service: service, account: account)
  }
}
