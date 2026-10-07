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
  public struct Context {
    public let id: String
    public let path: String
    public let capability = UUID().uuidString

    public init(id: String, path: String) {
      self.id = id
      self.path = path
    }
  }

  private let contexts: [String: Context]
  private let storage: KeychainSecretStorage
  private weak var delegate: (any EditorModuleSecretStorageDelegate)?

  public convenience init(contexts: [Context], delegate: any EditorModuleSecretStorageDelegate) {
    self.init(contexts: contexts, delegate: delegate, storage: .shared)
  }

  init(
    contexts: [Context],
    delegate: any EditorModuleSecretStorageDelegate,
    storage: KeychainSecretStorage
  ) {
    self.contexts = Dictionary(uniqueKeysWithValues: contexts.map { ($0.capability, $0) })
    self.delegate = delegate
    self.storage = storage
  }

  public func has(capability: String?, key: String) async -> String {
    await perform(capability: capability, key: key) { context, _ in
      try await BridgeMessage(("value", storage.has(namespace: context.id, key: key)))
    }
  }

  public func get(capability: String?, key: String) async -> String {
    await perform(capability: capability, key: key) { context, delegate in
      try await delegate.confirmSecretAccess(extensionID: context.id, path: context.path, key: key)
      let secret = try await storage.get(namespace: context.id, key: key)
      return BridgeMessage(("value", secret))
    }
  }

  public func set(capability: String?, key: String, value: String) async -> String {
    await perform(capability: capability, key: key) { context, _ in
      try await storage.set(namespace: context.id, key: key, value: value)
      return BridgeMessage()
    }
  }

  public func delete(capability: String?, key: String) async -> String {
    await perform(capability: capability, key: key) { context, _ in
      try await BridgeMessage(("value", storage.delete(namespace: context.id, key: key)))
    }
  }

  private func perform(
    capability: String?,
    key: String,
    operation: @MainActor (Context, any EditorModuleSecretStorageDelegate) async throws -> BridgeMessage
  ) async -> String {
    do {
      guard let capability, let context = contexts[capability], let delegate else {
        throw SecretStorageError.missingContext
      }

      guard !key.isEmpty else {
        throw SecretStorageError.invalidKey
      }

      return try await operation(context, delegate).jsonEncoded
    } catch {
      return BridgeMessage(("error", error.localizedDescription)).jsonEncoded
    }
  }
}
