//
//  KeychainSecretStorage.swift
//

import Foundation
import Security

public enum SecretStorageError: LocalizedError {
  case missingContext
  case invalidKey
  case cancelled
  case invalidData
  case keychain(OSStatus)

  public var errorDescription: String? {
    switch self {
    case .missingContext: return "Secret storage requires an active user script context."
    case .invalidKey: return "A secret storage key must not be empty."
    case .cancelled: return "Secret access was cancelled."
    case .invalidData: return "The stored secret is not a valid UTF-8 string."
    case .keychain(let status):
      let message = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown Keychain error."
      return "Keychain error \(status): \(message)"
    }
  }
}

actor KeychainSecretStorage {
  static let shared = KeychainSecretStorage()
  private let keychain: any SecretKeychain

  init(keychain: any SecretKeychain = SystemSecretKeychain()) {
    self.keychain = keychain
  }

  func has(namespace: String, key: String) throws -> Bool {
    var query = query(namespace: namespace, key: key)
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    let (status, _) = keychain.copyMatching(query)
    return try exists(status)
  }

  func get(namespace: String, key: String) throws -> String? {
    var query = query(namespace: namespace, key: key)
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    query[kSecReturnData as String] = true

    let (status, data) = keychain.copyMatching(query)
    guard try exists(status) else {
      return nil
    }

    guard let data, let value = String(data: data, encoding: .utf8) else {
      throw SecretStorageError.invalidData
    }

    return value
  }

  func set(namespace: String, key: String, value: String) throws {
    let query = query(namespace: namespace, key: key)
    let attributes: [String: Any] = [kSecValueData as String: Data(value.utf8)]

    var status = keychain.update(query, attributes: attributes)
    if status == errSecItemNotFound {
      var item = query.merging(attributes) { _, value in value }
      item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
      status = keychain.add(item)
      if status == errSecDuplicateItem {
        status = keychain.update(query, attributes: attributes)
      }
    }

    guard status == errSecSuccess else {
      throw SecretStorageError.keychain(status)
    }
  }

  func delete(namespace: String, key: String) throws -> Bool {
    try exists(keychain.delete(query(namespace: namespace, key: key)))
  }

  private func query(namespace: String, key: String) -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecUseDataProtectionKeychain as String: true,
      kSecAttrSynchronizable as String: false,
      kSecAttrService as String: "app.cyan.markedit.extension-secrets.\(namespace)",
      kSecAttrAccount as String: key,
    ]
  }

  private func exists(_ status: OSStatus) throws -> Bool {
    switch status {
    case errSecSuccess: return true
    case errSecItemNotFound: return false
    default: throw SecretStorageError.keychain(status)
    }
  }
}

protocol SecretKeychain: Sendable {
  func copyMatching(_ query: [String: Any]) -> (OSStatus, Data?)
  func add(_ attributes: [String: Any]) -> OSStatus
  func update(_ query: [String: Any], attributes: [String: Any]) -> OSStatus
  func delete(_ query: [String: Any]) -> OSStatus
}

private struct SystemSecretKeychain: SecretKeychain {
  func copyMatching(_ query: [String: Any]) -> (OSStatus, Data?) {
    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    return (status, result as? Data)
  }

  func add(_ attributes: [String: Any]) -> OSStatus {
    SecItemAdd(attributes as CFDictionary, nil)
  }

  func update(_ query: [String: Any], attributes: [String: Any]) -> OSStatus {
    SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
  }

  func delete(_ query: [String: Any]) -> OSStatus {
    SecItemDelete(query as CFDictionary)
  }
}
