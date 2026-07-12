//
//  ExtensionConfig.swift
//
//  Created by cyan on 7/11/26.
//

import Foundation
import MarkEditCore
import MarkEditKit

/// App-side state for editor extensions, stored as "extensions.json".
///
/// Mirrors `AppRuntimeConfig`, the remote catalog is fetched by `ExtensionRegistry`.
public enum ExtensionConfig {
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
  public enum UpdateCheck: String, Codable, Sendable {
    case never
    case onLaunch
    case daily
    case weekly
  }

  /// What to do once an update is found.
  public enum UpdateStrategy: String, Codable, Sendable {
    case manual
    case prompt
    case automatic
  }

  /// A single installed extension, array order is injection order.
  public struct Installed: Codable, Equatable, Sendable {
    public let id: String
    public let version: String?
    public let url: String?
    public let sha256: String?
    public let file: String
    public let enabled: Bool? // Absent means enabled, tolerates hand-edited files
    public let updateCheck: UpdateCheck?
    public let installDate: String?

    public init(
      id: String,
      version: String?,
      url: String?,
      sha256: String?,
      file: String,
      enabled: Bool?,
      updateCheck: UpdateCheck?,
      installDate: String?
    ) {
      self.id = id
      self.version = version
      self.url = url
      self.sha256 = sha256
      self.file = file
      self.enabled = enabled
      self.updateCheck = updateCheck
      self.installDate = installDate
    }
  }

  /// Registry index url, overridable to a mirror.
  public static var registryURL: URL? {
    let string = currentDefinition?.registryURL ?? Constants.defaultRegistryURL
    return URL(string: string)
  }

  public static var updateCheck: UpdateCheck {
    currentDefinition?.updateCheck ?? .weekly
  }

  public static var updateStrategy: UpdateStrategy {
    // Never automatic by default, injected code is arbitrary JavaScript
    currentDefinition?.updateStrategy ?? .prompt
  }

  public static var installed: [Installed] {
    currentDefinition?.installed ?? []
  }

  /// Filenames of enabled installed extensions, in injection order.
  public static var enabledFileNames: [String] {
    installed.filter { $0.enabled != false }.map(\.file)
  }

  /// Syncs installed[] with the scripts on disk.
  ///
  /// The filesystem is the source of truth: records whose file was removed are dropped,
  /// untracked script files are adopted in discovery order, and nothing is written when
  /// already in sync.
  public static func reconcileInstalled() {
    let onDiskURLs = ExtensionEnvironment.scriptsDirectory.sortedFiles(types: ["js"])
    let onDiskFiles = onDiskURLs.map(\.lastPathComponent)

    let installed = onDiskDefinition?.installed ?? []
    let tracked = Set(installed.map(\.file))
    let existing = Set(onDiskFiles)

    // Drop records whose script file was removed, keep the rest in order
    let retained = installed.filter {
      existing.contains($0.file)
    }

    // Adopt script files not yet tracked, in discovery order
    let adopted = onDiskURLs
      .filter { !tracked.contains($0.lastPathComponent) }
      .map { Installed(adopting: $0) }

    let reconciled = retained + adopted
    guard reconciled != installed else {
      return
    }

    persist(installed: reconciled)
  }

  /// Persists an installed extension, replacing any existing entry with the same id.
  ///
  /// Reads fresh from disk (not the cached definition) so repeated installs compose.
  public static func upsertInstalled(_ entry: Installed) {
    var installed = onDiskDefinition?.installed ?? []
    installed.removeAll { $0.id == entry.id }
    installed.append(entry)
    persist(installed: installed)
  }

  /// Derives a kebab-case id from a script file name, e.g. "markedit-preview.js" -> "markedit-preview".
  public static func identifier(fromFileName fileName: String) -> String {
    let url = URL(fileURLWithPath: fileName).deletingPathExtension()
    let kebabCased = url.lastPathComponent.kebabCased
    return kebabCased.isEmpty ? "extension" : kebabCased
  }

  public static var defaultContents: String {
    encode(definition: defaultDefinition)?.toString() ?? ""
  }
}

// MARK: - Private

private extension ExtensionConfig {
  enum Constants {
    static let defaultRegistryURL = "https://raw.githubusercontent.com/MarkEdit-app/extensions/main/index.json"
    static let schemaURL = "https://raw.githubusercontent.com/MarkEdit-app/schemas/main/extensions.json"
  }

  static let fileData = try? Data(contentsOf: ExtensionEnvironment.extensionsURL)

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
    guard let data = try? Data(contentsOf: ExtensionEnvironment.extensionsURL) else {
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
      try data.write(to: ExtensionEnvironment.extensionsURL, options: .atomic)
    } catch {
      Logger.log(.error, "Failed to write extensions.json")
    }
  }
}

public extension ExtensionConfig.Installed {
  /// Adopts a local script file as an untracked extension.
  ///
  /// The filesystem supplies `sha256` (hash of the current bytes) and `installDate` (file
  /// creation date); `version` and `url` stay nil until the registry claims it.
  init(adopting fileURL: URL) {
    let fileName = fileURL.lastPathComponent
    let sha256 = (try? Data(contentsOf: fileURL))?.sha256Hash
    let created = (try? fileURL.resourceValues(forKeys: [.creationDateKey]))?.creationDate

    self.init(
      id: ExtensionConfig.identifier(fromFileName: fileName),
      version: nil,
      url: nil,
      sha256: sha256,
      file: fileName,
      enabled: true,
      updateCheck: nil,
      installDate: created.map { ISO8601DateFormatter().string(from: $0) }
    )
  }

  /// A freshly downloaded record that keeps user-managed fields from a previous install.
  func merging(preserving previous: Self) -> Self {
    Self(
      id: id,
      version: version,
      url: url,
      sha256: sha256,
      file: file,
      enabled: previous.enabled,
      updateCheck: previous.updateCheck,
      installDate: installDate
    )
  }
}
