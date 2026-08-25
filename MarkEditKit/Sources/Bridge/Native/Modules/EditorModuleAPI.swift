//
//  EditorModuleAPI.swift
//
//  Created by cyan on 10/4/24.
//

import Foundation
import UniformTypeIdentifiers

#if os(macOS)
  import AppKit
#endif

@MainActor
public protocol EditorModuleAPIDelegate: AnyObject {
  func editorAPISaveDocument(_ sender: EditorModuleAPI) async -> Bool
  func editorAPICloseDocument(_ sender: EditorModuleAPI) -> Bool
  func editorAPI(_ sender: EditorModuleAPI, addMainMenuItems items: [(String, WebMenuItem)])
  func editorAPI(_ sender: EditorModuleAPI, showContextMenu items: [WebMenuItem], location: WebPoint)
  func editorAPI(
    _ sender: EditorModuleAPI,
    alertWith title: String?,
    message: String?,
    buttons: [String]?
  ) async -> Int
  func editorAPI(
    _ sender: EditorModuleAPI,
    showTextBox title: String?,
    placeholder: String?,
    defaultValue: String?
  ) async -> String?
  func editorAPI(_ sender: EditorModuleAPI, showSavePanel data: Data, fileName: String?) async -> Bool
  func editorAPI(_ sender: EditorModuleAPI, runService name: String, input: String?) async -> Bool
  func editorAPIOpenFile(_ sender: EditorModuleAPI, fileURL: URL) -> Bool
  func editorAPIGetFileURL(_ sender: EditorModuleAPI, path: String?) -> URL?
  func editorAPI(_ sender: EditorModuleAPI, restoreFileVersionContent content: String) async -> Bool
  func editorAPITerminateApp(_ sender: EditorModuleAPI)
  func editorAPIRelaunchApp(_ sender: EditorModuleAPI)
}

public final class EditorModuleAPI: NativeModuleAPI {
  private weak var delegate: EditorModuleAPIDelegate?
  private var fileVersionURL: URL?
  private var fileVersionMap = [String: NSFileVersion]()

  public init(delegate: EditorModuleAPIDelegate) {
    self.delegate = delegate
  }

  public func saveDocument() async -> Bool {
    await delegate?.editorAPISaveDocument(self) == true
  }

  public func closeDocument() async -> Bool {
    delegate?.editorAPICloseDocument(self) == true
  }

  public func addMainMenuItems(items: [WebMenuItem]) {
    delegate?.editorAPI(self, addMainMenuItems: items.map { item in
      (item.uniqueID.sha256Hash, item)
    })
  }

  public func showContextMenu(items: [WebMenuItem], location: WebPoint) {
    delegate?.editorAPI(self, showContextMenu: items, location: location)
  }

  public func showAlert(title: String?, message: String?, buttons: [String]?) async -> Int {
    await delegate?.editorAPI(self, alertWith: title, message: message, buttons: buttons) ?? 0
  }

  public func showTextBox(title: String?, placeholder: String?, defaultValue: String?) async -> String? {
    await delegate?.editorAPI(self, showTextBox: title, placeholder: placeholder, defaultValue: defaultValue)
  }

  public func showSavePanel(options: SavePanelOptions) async -> Bool {
    await delegate?.editorAPI(self, showSavePanel: options.decodedData, fileName: options.fileName) == true
  }

  public func runService(name: String, input: String?) async -> Bool {
    (await delegate?.editorAPI(self, runService: name, input: input)) == true
  }

  public func openFile(path: String) async -> Bool {
    delegate?.editorAPIOpenFile(self, fileURL: URL(filePath: path)) == true
  }

  public func createFile(options: CreateFileOptions) async -> Bool {
    guard let fileURL = delegate?.editorAPIGetFileURL(self, path: options.path) else {
      return false
    }

    var (fileExists, isDirectory) = FileManager.default.fileExists(at: fileURL)
    if fileExists && isDirectory && options.overwrites == true {
      try? FileManager.default.removeItem(at: fileURL)
      fileExists = false
    }

    do {
      if options.isDirectory == true {
        try FileManager.default.createDirectory(
          at: fileURL,
          withIntermediateDirectories: true
        )
      } else {
        if !fileExists {
          try options.decodedData.write(to: fileURL, options: .atomic)
        } else if options.overwrites == true {
          try options.decodedData.overwrite(to: fileURL)
        }
      }

      return true
    } catch {
      return false
    }
  }

  public func deleteFile(path: String) async -> Bool {
    guard let fileURL = delegate?.editorAPIGetFileURL(self, path: path) else {
      return false
    }

    do {
      try FileManager.default.removeItem(at: fileURL)
      return true
    } catch {
      return false
    }
  }

  public func moveFile(options: MoveFileOptions) async -> Bool {
    guard let sourceURL = delegate?.editorAPIGetFileURL(self, path: options.source) else {
      return false
    }

    guard let destinationURL = delegate?.editorAPIGetFileURL(self, path: options.destination) else {
      return false
    }

    do {
      if FileManager.default.fileExists(at: destinationURL).fileExists {
        guard options.overwrites == true else {
          return false
        }

        try FileManager.default.removeItem(at: destinationURL)
      }

      try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
      return true
    } catch {
      return false
    }
  }

  public func revealFile(path: String?) async -> Bool {
    guard let fileURL = delegate?.editorAPIGetFileURL(self, path: path) else {
      return false
    }

  #if os(macOS)
    guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
      return false
    }

    NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    return true
  #else
    Logger.assertFail("Missing implementation, revealing files requires AppKit")
    return false
  #endif
  }

  public func listFiles(path: String) async -> [String]? {
    guard let fileURL = delegate?.editorAPIGetFileURL(self, path: path) else {
      return nil
    }

    let fileManager = FileManager.default
    let filePath = fileURL.path(percentEncoded: false)
    return try? fileManager.contentsOfDirectory(atPath: filePath)
  }

  public func getFileContent(path: String?) async -> String? {
    guard let fileURL = delegate?.editorAPIGetFileURL(self, path: path) else {
      return nil
    }

    return try? Data(contentsOf: fileURL).toString()
  }

  public func getFileObject(path: String?) async -> String? {
    guard let fileURL = delegate?.editorAPIGetFileURL(self, path: path) else {
      return nil
    }

    guard let fileData = try? Data(contentsOf: fileURL).base64EncodedString() else {
      return nil
    }

    var json: [String: Any] = [
      "data": fileData,
    ]

    if let uniformType = UTType(filenameExtension: fileURL.pathExtension) {
      json["typeIdentifier"] = uniformType.identifier
      json["mimeType"] = uniformType.preferredMIMEType
      json["filenameExtension"] = uniformType.preferredFilenameExtension
    }

    return try? JSONSerialization.data(withJSONObject: json).toString()
  }

  public func getFileInfo(path: String?) async -> String? {
    guard let fileURL = delegate?.editorAPIGetFileURL(self, path: path) else {
      return nil
    }

    guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path) else {
      return nil
    }

    let json: [String: Any] = [
      "filePath": fileURL.path,
      "fileSize": Double(attributes[.size] as? Int64 ?? 0),
      "creationDate": (attributes[.creationDate] as? Date ?? .distantPast).timeIntervalSince1970,
      "modificationDate": (attributes[.modificationDate] as? Date ?? .distantPast).timeIntervalSince1970,
      "parentPath": fileURL.deletingLastPathComponent().path,
      "isDirectory": (attributes[.type] as? FileAttributeType) == .typeDirectory,
    ]

    return try? JSONSerialization.data(withJSONObject: json).toString()
  }

  public func getPasteboardItems() async -> String? {
  #if os(macOS)
    let pasteboard = NSPasteboard.general
    let types = pasteboard.types ?? []

    let json: [[String: String]] = types.compactMap { type in
      guard let data = pasteboard.data(forType: type) else {
        return nil
      }

      var dict = [
        "type": type.rawValue,
        "data": data.base64EncodedString(),
      ]

      dict["string"] = data.toString()
      return dict
    }

    return try? JSONSerialization.data(withJSONObject: json).toString()
  #else
    Logger.assertFail("Missing implementation, consider using web api directly")
    return []
  #endif
  }

  public func getPasteboardString() async -> String? {
  #if os(macOS)
    return NSPasteboard.general.string(forType: .string)
  #else
    Logger.assertFail("Missing implementation, consider using web api directly")
    return nil
  #endif
  }

  public func terminateApp() {
    delegate?.editorAPITerminateApp(self)
  }

  public func relaunchApp() {
    delegate?.editorAPIRelaunchApp(self)
  }
}

// MARK: - File Versions

public extension EditorModuleAPI {
  func getFileVersions() async -> String? {
    guard let fileURL = delegate?.editorAPIGetFileURL(self, path: nil) else {
      clearFileVersions()
      return nil
    }

    if fileVersionURL != fileURL {
      clearFileVersions()
      fileVersionURL = fileURL
    }

    let nonlocalVersions = (try? await NSFileVersion.nonlocalVersionsOfItem(at: fileURL)) ?? []
    guard isCurrentFileVersionURL(fileURL) else {
      return nil
    }

    var idsByVersion = [FileVersionKey: String]()
    for (id, version) in fileVersionMap {
      if let key = FileVersionKey(version) {
        idsByVersion[key] = id
      }
    }

    let localVersions = NSFileVersion.otherVersionsOfItem(at: fileURL) ?? []
    var seenVersions = Set<FileVersionKey>()

    let versions = (localVersions + nonlocalVersions).filter {
      guard let key = FileVersionKey($0) else {
        return false
      }

      return seenVersions.insert(key).inserted
    }
    .newestToOldest(throttle: false)

    var newVersionMap = [String: NSFileVersion]()
    let result: [[String: Any]] = versions.compactMap { version in
      guard let key = FileVersionKey(version), let modificationDate = version.modificationDate else {
        return nil
      }

      let id = idsByVersion[key] ?? UUID().uuidString
      newVersionMap[id] = version
      return [
        "id": id,
        "modificationDate": modificationDate.timeIntervalSince1970,
      ]
    }

    fileVersionMap = newVersionMap
    return try? JSONSerialization.data(withJSONObject: result).toString()
  }

  func getFileVersionContent(id: String) async -> String? {
    guard let version = currentFileVersion(id: id), let key = FileVersionKey(version) else {
      return nil
    }

    guard await version.fetchLocalContents() else {
      return nil
    }

    guard let currentVersion = currentFileVersion(id: id), FileVersionKey(currentVersion) == key else {
      return nil
    }

    return try? Data(contentsOf: currentVersion.url).toString()
  }

  func restoreFileVersion(id: String) async -> Bool {
    guard let version = currentFileVersion(id: id), let key = FileVersionKey(version) else {
      return false
    }

    guard await version.fetchLocalContents() else {
      return false
    }

    guard let currentVersion = currentFileVersion(id: id), FileVersionKey(currentVersion) == key else {
      return false
    }

    guard let content = try? Data(contentsOf: currentVersion.url).toString() else {
      return false
    }

    return await delegate?.editorAPI(self, restoreFileVersionContent: content) == true
  }

  func deleteFileVersions(ids: [String]) async -> Bool {
    let uniqueIDs = Set(ids)
    guard !uniqueIDs.isEmpty, uniqueIDs.allSatisfy({ currentFileVersion(id: $0) != nil }) else {
      return false
    }

    guard let fileVersionURL else {
      return false
    }

    let versions = uniqueIDs.compactMap { id -> (String, NSFileVersion, FileVersionKey)? in
      guard let version = fileVersionMap[id], let key = FileVersionKey(version) else {
        return nil
      }

      return (id, version, key)
    }

    guard versions.count == uniqueIDs.count else {
      return false
    }

    for (id, version, key) in versions {
      guard isCurrentFileVersionURL(fileVersionURL) else {
        return false
      }

      do {
        try await version.removeFromDisk()
      } catch {
        Logger.log(.error, error.localizedDescription)
        return false
      }

      guard isCurrentFileVersionURL(fileVersionURL) else {
        return false
      }

      if let currentVersion = fileVersionMap[id], FileVersionKey(currentVersion) != key {
        return false
      }

      fileVersionMap.removeValue(forKey: id)
    }

    return true
  }
}

// MARK: - Internal

extension CreateFileOptions: WebDataTransfer {}
extension SavePanelOptions: WebDataTransfer {}

// MARK: - Private

private extension EditorModuleAPI {
  func currentFileVersion(id: String) -> NSFileVersion? {
    guard isCurrentFileVersionURL() else {
      return nil
    }

    return fileVersionMap[id]
  }

  func isCurrentFileVersionURL(_ expectedURL: URL? = nil) -> Bool {
    guard let fileURL = delegate?.editorAPIGetFileURL(self, path: nil) else {
      return false
    }

    guard fileURL == fileVersionURL, expectedURL == nil || fileURL == expectedURL else {
      if expectedURL == nil || fileVersionURL == expectedURL {
        clearFileVersions()
      }

      return false
    }

    return true
  }

  func clearFileVersions() {
    fileVersionMap.removeAll()
    fileVersionURL = nil
  }
}

private struct FileVersionKey: Hashable {
  let persistentIdentifier: Data

  init?(_ version: NSFileVersion) {
    guard let persistentIdentifier = try? NSKeyedArchiver.archivedData(
      withRootObject: version.persistentIdentifier,
      requiringSecureCoding: false
    ) else {
      return nil
    }

    self.persistentIdentifier = persistentIdentifier
  }
}

private extension WebMenuItem {
  var uniqueID: String {
    [
      "\(separator)",
      title ?? "",
      key ?? "",
      "\(modifiers ?? [])",
      "[\((children ?? []).map { $0.uniqueID }.joined(separator: ", "))]",
    ].joined(separator: ", ")
  }
}

private protocol WebDataTransfer {
  var string: String? { get }
  var data: String? { get }
}

private extension WebDataTransfer {
  var decodedData: Data {
    if let source = data, let data = Data(base64Encoded: source, options: .ignoreUnknownCharacters) {
      return data
    }

    if let source = string, let data = source.data(using: .utf8) {
      return data
    }

    return Data()
  }
}

private extension FileManager {
  func fileExists(at url: URL) -> (fileExists: Bool, isDirectory: Bool) {
    var isDirectory: ObjCBool = false
    let fileExists = fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory)
    return (fileExists, isDirectory.boolValue)
  }
}

private extension Data {
  /// Overwrites the contents of the file at `url` in place,
  /// preserving the inode, permissions, and extended attributes.
  ///
  /// Writes the new payload from offset 0 first, then truncates any
  /// remaining tail. This avoids ever observing an empty file: if a
  /// crash happens between the two steps, the file still contains
  /// the full new content (possibly followed by stale tail bytes),
  /// rather than being truncated to zero length.
  func overwrite(to url: URL) throws {
    let handle = try FileHandle(forWritingTo: url)
    defer { try? handle.close() }

    try handle.seek(toOffset: 0)
    try handle.write(contentsOf: self)
    try handle.truncate(atOffset: UInt64(count))
  }
}
