//
//  EditorIndexHtml.swift
//
//  Created by cyan on 7/27/26.
//

import Foundation
import os.log

/**
 index.html built by CoreEditor, shared between the app and its extensions.
 */
public enum EditorIndexHtml {
  public static var sharedFileExists: Bool {
    guard let url = sharedURL else {
      return false
    }

    return FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
  }

  public static func fromAppBundle(config: EditorConfig, userSettings: String) -> String {
    toHtml(template: bundledContents, config: config, userSettings: userSettings)
  }

  public static func fromSharedContainer(config: EditorConfig) -> String {
    toHtml(
      template: sharedContents,
      config: config,
      userSettings: userSettings(at: URL.sharedContainerURL?.appending(
        path: "Shared/settings.json",
        directoryHint: .notDirectory
      )) ?? "{}"
    )
  }

  public static func copyToSharedContainer() {
    guard let targetURL = sharedURL, let data = bundledData else {
      return
    }

    guard (try? Data(contentsOf: targetURL)) != data else {
      return
    }

    do {
      try FileManager.default.createDirectory(
        at: targetURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )

      try data.write(to: targetURL, options: .atomic)
    } catch {
      assertionFailure("Failed to copy index.html to shared container: \(error)")
    }
  }

  static func userSettings(at url: URL?) -> String? {
    guard let url else {
      return nil
    }

    do {
      let data = try Data(contentsOf: url)
      let object = try JSONSerialization.jsonObject(with: data)
      guard let settings = object as? [String: Any] else {
        os_logger.log(level: .error, "Shared settings must be a JSON object: \(url)")
        return nil
      }

      let json = try JSONSerialization.data(withJSONObject: settings)
      return String(bytes: json, encoding: .utf8)
    } catch {
      os_logger.log(level: .error, "Failed to read shared settings at \(url): \(error)")
      return nil
    }
  }
}

// MARK: - Private

private extension EditorIndexHtml {
  static let sharedURL = URL.sharedContainerURL?.appending(
    path: "Shared/index.html",
    directoryHint: .notDirectory
  )

  static let bundledContents: String = {
    bundledData?.toString() ?? ""
  }()

  static var bundledData: Data? {
    guard let url = Bundle.main.url(forResource: "index", withExtension: "html") else {
      assertionFailure("Missing dist/index.html to set up the editor")
      return nil
    }

    return try? Data(contentsOf: url)
  }

  static var sharedContents: String {
    guard let url = sharedURL else {
      return ""
    }

    return (try? Data(contentsOf: url).toString()) ?? ""
  }

  static func toHtml(
    template: String,
    config: EditorConfig,
    userSettings: String
  ) -> String {
    // Replace the later placeholder first to avoid searching arbitrarily large inserted JSON
    template
      .replacing("\"{{USER_SETTINGS}}\"", with: userSettings, maxReplacements: 1)
      .replacing("\"{{EDITOR_CONFIG}}\"", with: config.jsonEncoded, maxReplacements: 1)
  }
}

private let os_logger = os.Logger()
