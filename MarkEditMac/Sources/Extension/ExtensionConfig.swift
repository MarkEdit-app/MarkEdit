//
//  ExtensionConfig.swift
//  MarkEditMac
//
//  Created by cyan on 7/11/26.
//

import Foundation
import MarkEditCore
import MarkEditKit

/// App-side state for editor extensions, stored as "extensions.json".
///
/// Mirrors `AppRuntimeConfig`, the remote catalog is fetched by `ExtensionRegistry`.
enum ExtensionConfig {
  struct Definition: Codable {
    let __schema: String?
    let registryURL: String?
    let updateCheck: UpdateCheck?
    let updateStrategy: UpdateStrategy?
    let installed: [Installed]?

    enum CodingKeys: String, CodingKey {
      case __schema = "$schema"
      case registryURL = "registry.url"
      case updateCheck = "registry.updateCheck"
      case updateStrategy = "registry.updateStrategy"
      case installed
    }
  }

  /// How often to check for updates.
  enum UpdateCheck: String, Codable {
    case never
    case onLaunch
    case daily
    case weekly
  }

  /// What to do once an update is found.
  enum UpdateStrategy: String, Codable {
    case manual
    case prompt
    case automatic
  }

  /// A single installed extension, array order is injection order.
  struct Installed: Codable, Equatable {
    let id: String
    let version: String?
    let url: String?
    let sha256: String?
    let file: String
    let enabled: Bool? // Absent means enabled, tolerates hand-edited files
    let updateCheck: UpdateCheck?
    let installDate: String?
  }

  /// Registry index url, overridable to a mirror.
  static var registryURL: URL? {
    let string = currentDefinition?.registryURL ?? Constants.defaultRegistryURL
    return URL(string: string)
  }

  static var updateCheck: UpdateCheck {
    currentDefinition?.updateCheck ?? .weekly
  }

  static var updateStrategy: UpdateStrategy {
    // Never automatic by default, injected code is arbitrary JavaScript
    currentDefinition?.updateStrategy ?? .prompt
  }

  static var installed: [Installed] {
    currentDefinition?.installed ?? []
  }

  /// Filenames of enabled installed extensions, in injection order.
  static var enabledFileNames: [String] {
    installed.filter { $0.enabled != false }.map(\.file)
  }

  /// Syncs installed[] with the scripts on disk.
  ///
  /// The filesystem is the source of truth: records whose file was removed are dropped,
  /// untracked script files are adopted in discovery order, and nothing is written when
  /// already in sync.
  static func reconcileInstalled() {
    let onDiskFiles = AppCustomization.scriptsDirectory.fileURL
      .sortedFiles(types: ["js"])
      .map(\.lastPathComponent)

    let installed = onDiskDefinition?.installed ?? []
    let tracked = Set(installed.map(\.file))
    let existing = Set(onDiskFiles)

    // Drop records whose script file was removed, keep the rest in order
    let retained = installed.filter {
      existing.contains($0.file)
    }

    // Adopt script files not yet tracked, in discovery order
    let adopted = onDiskFiles
      .filter { !tracked.contains($0) }
      .map { Installed(fileName: $0) }

    let reconciled = retained + adopted
    guard reconciled != installed else {
      return
    }

    persist(installed: reconciled)
  }

  /// Persists an installed extension, replacing any existing entry with the same id.
  ///
  /// Reads fresh from disk (not the cached definition) so repeated installs compose.
  static func upsertInstalled(_ entry: Installed) {
    var installed = onDiskDefinition?.installed ?? []
    installed.removeAll { $0.id == entry.id }
    installed.append(entry)
    persist(installed: installed)
  }

  /// Derives a kebab-case id from a script file name, e.g. "markedit-preview.js" -> "markedit-preview".
  static func identifier(fromFileName fileName: String) -> String {
    let url = URL(fileURLWithPath: fileName).deletingPathExtension()
    let kebabCased = url.lastPathComponent.kebabCased
    return kebabCased.isEmpty ? "extension" : kebabCased
  }

  static var defaultContents: String {
    encode(definition: defaultDefinition)?.toString() ?? ""
  }
}

// MARK: - Private

private extension ExtensionConfig {
  enum Constants {
    static let defaultRegistryURL = "https://raw.githubusercontent.com/MarkEdit-app/extensions/main/index.json"
    static let schemaURL = "https://raw.githubusercontent.com/MarkEdit-app/schemas/main/extensions.json"
  }

  static let fileData = try? Data(contentsOf: AppCustomization.extensions.fileURL)

  static let defaultDefinition = Definition(
    __schema: Constants.schemaURL,
    registryURL: Constants.defaultRegistryURL,
    updateCheck: .weekly,
    updateStrategy: .prompt,
    installed: []
  )

  static let currentDefinition: Definition? = {
    guard let fileData else {
      Logger.log(.error, "Missing extensions.json to proceed")
      return nil
    }

    guard let definition = try? JSONDecoder().decode(Definition.self, from: fileData) else {
      Logger.log(.error, "Invalid json object was found: \(fileData)")
      return nil
    }

    return definition
  }()

  static func encode(definition: Definition) -> Data? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

    let jsonData = try? encoder.encode(definition)
    Logger.assert(jsonData != nil, "Failed to encode object: \(definition)")

    return jsonData
  }

  /// Reads the definition fresh from disk, bypassing the cached `currentDefinition`.
  static var onDiskDefinition: Definition? {
    guard let data = try? Data(contentsOf: AppCustomization.extensions.fileURL) else {
      return nil
    }

    return try? JSONDecoder().decode(Definition.self, from: data)
  }

  static func persist(installed: [Installed]) {
    let base = onDiskDefinition ?? defaultDefinition
    let definition = Definition(
      __schema: base.__schema ?? Constants.schemaURL,
      registryURL: base.registryURL,
      updateCheck: base.updateCheck,
      updateStrategy: base.updateStrategy,
      installed: installed
    )

    guard let data = encode(definition: definition) else {
      return
    }

    do {
      try data.write(to: AppCustomization.extensions.fileURL, options: .atomic)
    } catch {
      Logger.log(.error, "Failed to write extensions.json")
    }
  }
}

extension ExtensionConfig.Installed {
  /// Adopts a local script file as an untracked extension, id derived from the file name.
  init(fileName: String) {
    self.init(
      id: ExtensionConfig.identifier(fromFileName: fileName),
      version: nil,
      url: nil,
      sha256: nil,
      file: fileName,
      enabled: nil,
      updateCheck: nil,
      installDate: nil
    )
  }
}
