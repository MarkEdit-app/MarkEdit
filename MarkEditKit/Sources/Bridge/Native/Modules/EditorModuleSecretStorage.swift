//
//  EditorModuleSecretStorage.swift
//

import Foundation
import MarkEditCore

@MainActor
public protocol EditorModuleSecretStorageDelegate: AnyObject {
  func confirmSecretAccess(extensionID: String, path: String, key: String) async throws
}

@MainActor
public final class EditorModuleSecretStorage: NativeModuleSecretStorage {
  private let scripts: [String: String]
  private let storage: KeychainSecretStorage
  private weak var delegate: (any EditorModuleSecretStorageDelegate)?

  public convenience init(scripts: [String: String], delegate: any EditorModuleSecretStorageDelegate) {
    self.init(scripts: scripts, delegate: delegate, storage: .shared)
  }

  init(
    scripts: [String: String],
    delegate: any EditorModuleSecretStorageDelegate,
    storage: KeychainSecretStorage
  ) {
    self.scripts = scripts
    self.delegate = delegate
    self.storage = storage
  }

  public func has(path: String, key: String) async -> String {
    await perform(path: path, key: key) { id, _ in
      try await BridgeMessage(("value", storage.has(namespace: id, key: key)))
    }
  }

  public func get(path: String, key: String) async -> String {
    await perform(path: path, key: key) { id, delegate in
      try await delegate.confirmSecretAccess(extensionID: id, path: path, key: key)
      let secret = try await storage.get(namespace: id, key: key)
      return BridgeMessage(("value", secret))
    }
  }

  public func set(path: String, key: String, value: String) async -> String {
    await perform(path: path, key: key) { id, _ in
      try await storage.set(namespace: id, key: key, value: value)
      return BridgeMessage()
    }
  }

  public func delete(path: String, key: String) async -> String {
    await perform(path: path, key: key) { id, _ in
      try await BridgeMessage(("value", storage.delete(namespace: id, key: key)))
    }
  }

  private func perform(
    path: String,
    key: String,
    operation: @MainActor (String, any EditorModuleSecretStorageDelegate) async throws -> BridgeMessage
  ) async -> String {
    do {
      guard let id = scripts[path], let delegate else {
        throw SecretStorageError.missingContext
      }

      guard !key.isEmpty else {
        throw SecretStorageError.invalidKey
      }

      return try await operation(id, delegate).jsonEncoded
    } catch {
      return BridgeMessage(("error", error.localizedDescription)).jsonEncoded
    }
  }
}
