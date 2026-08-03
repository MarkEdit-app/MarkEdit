//
//  BundleVerifier.swift
//
//  Created by cyan on 8/2/26.
//

import Foundation
import Security

/**
 Validates identity and code signatures for in-place updates.
 */
public enum BundleVerifier {
  public enum Failure: LocalizedError, Equatable {
    case unreadable(String)
    case unreadableBundle(String)
    case requirementMissing(String)
    case rejected(String)
    case identifierMismatch
    case notNewer(String)

    public var errorDescription: String? {
      switch self {
      case .unreadable(let path):
        return "No code signature could be read from \(path)"
      case .unreadableBundle(let path):
        return "The bundle at \(path) could not be read"
      case .requirementMissing(let path):
        return "\(path) has no designated requirement"
      case .rejected(let reason):
        return "The update was rejected: \(reason)"
      case .identifierMismatch:
        return "The downloaded application does not match the installed one"
      case .notNewer(let version):
        return "The downloaded application is version \(version), not newer than the installed one"
      }
    }
  }

  /// Confirms the candidate is a newer version of the same app.
  public static func checkIdentity(of candidate: String, matching reference: String) throws {
    let candidate = try infoDictionary(of: candidate)
    let reference = try infoDictionary(of: reference)

    guard candidate.bundleIdentifier == reference.bundleIdentifier else {
      throw Failure.identifierMismatch
    }

    // Enforce version ordering at the trust boundary
    guard candidate.shortVersion.compare(reference.shortVersion, options: .numeric) == .orderedDescending else {
      throw Failure.notNewer(candidate.shortVersion)
    }
  }

  public static func designatedRequirement(of path: String) throws -> SecRequirement {
    var requirement: SecRequirement?
    let status = SecCodeCopyDesignatedRequirement(try staticCode(at: path), [], &requirement)

    guard status == errSecSuccess, let requirement else {
      throw Failure.requirementMissing(path)
    }

    return requirement
  }

  public static func check(path: String, against requirement: SecRequirement) throws {
    let flags = SecCSFlags(rawValue: kSecCSCheckAllArchitectures | kSecCSCheckNestedCode | kSecCSStrictValidate)
    var error: Unmanaged<CFError>?

    guard SecStaticCodeCheckValidityWithErrors(try staticCode(at: path), flags, requirement, &error) == errSecSuccess else {
      let failure = error?.takeRetainedValue()
      throw Failure.rejected(failure.map { CFErrorCopyDescription($0) as String } ?? "unknown reason")
    }
  }
}

// MARK: - Private

private extension BundleVerifier {
  /// Reads the bundle dictionary without `Bundle` caching.
  static func infoDictionary(of path: String) throws -> [String: Any] {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let info = CFBundleCopyInfoDictionaryInDirectory(url) as? [String: Any] else {
      throw Failure.unreadableBundle(path)
    }

    return info
  }

  static func staticCode(at path: String) throws -> SecStaticCode {
    var code: SecStaticCode?
    let url = URL(fileURLWithPath: path) as CFURL

    guard SecStaticCodeCreateWithPath(url, [], &code) == errSecSuccess, let code else {
      throw Failure.unreadable(path)
    }

    return code
  }
}

private extension [String: Any] {
  var bundleIdentifier: String {
    self["CFBundleIdentifier"] as? String ?? ""
  }

  var shortVersion: String {
    self["CFBundleShortVersionString"] as? String ?? ""
  }
}
