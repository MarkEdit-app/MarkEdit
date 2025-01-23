//
//  EditorModuleCore.swift
//
//  Created by cyan on 12/24/22.
//

import Foundation

@MainActor
public protocol EditorModuleCoreDelegate: AnyObject {
  func editorCoreGetFileURL(_ sender: EditorModuleCore) -> URL?
  func editorCoreWindowDidLoad(_ sender: EditorModuleCore)
  func editorCoreBackgroundColorDidChange(_ sender: EditorModuleCore, color: UInt32)
  func editorCoreViewportScaleDidChange(_ sender: EditorModuleCore)
  func editorCoreViewDidUpdate(
    _ sender: EditorModuleCore,
    contentEdited: Bool,
    compositionEnded: Bool,
    isDirty: Bool,
    selectedLineColumn: LineColumnInfo
  )
  func editorCoreContentHeightDidChange(_ sender: EditorModuleCore, bottomPanelHeight: Double)
  func editorCoreContentOffsetDidChange(_ sender: EditorModuleCore)
  func editorCoreCompositionEnded(_ sender: EditorModuleCore, selectedLineColumn: LineColumnInfo)
  func editorCoreLinkClicked(_ sender: EditorModuleCore, link: String)
}

public final class EditorModuleCore: NativeModuleCore {
  private weak var delegate: EditorModuleCoreDelegate?

  public init(delegate: EditorModuleCoreDelegate) {
    self.delegate = delegate
  }

  public func getFileInfo() -> String? {
    guard let fileURL = delegate?.editorCoreGetFileURL(self) else {
      return nil
    }

    let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
    Logger.assert(attributes != nil, "Cannot get file attributes of: \(fileURL)")

    let json: [String: Any] = [
      "filePath": fileURL.path,
      "fileSize": Double(attributes?[.size] as? Int64 ?? 0),
      "creationDate": (attributes?[.creationDate] as? Date ?? .distantPast).timeIntervalSince1970,
      "modificationDate": (attributes?[.modificationDate] as? Date ?? .distantPast).timeIntervalSince1970,
    ]

    return try? JSONSerialization.data(withJSONObject: json).toString()
  }

  public func notifyWindowDidLoad() {
    delegate?.editorCoreWindowDidLoad(self)
  }

  public func notifyBackgroundColorDidChange(color: Int) {
    delegate?.editorCoreBackgroundColorDidChange(self, color: UInt32(color))
  }

  public func notifyViewportScaleDidChange() {
    delegate?.editorCoreViewportScaleDidChange(self)
  }

  public func notifyViewDidUpdate(
    contentEdited: Bool,
    compositionEnded: Bool,
    isDirty: Bool,
    selectedLineColumn: LineColumnInfo
  ) {
    delegate?.editorCoreViewDidUpdate(
      self,
      contentEdited: contentEdited,
      compositionEnded: compositionEnded,
      isDirty: isDirty,
      selectedLineColumn: selectedLineColumn
    )
  }

  public func notifyContentHeightDidChange(bottomPanelHeight: Double) {
    delegate?.editorCoreContentHeightDidChange(self, bottomPanelHeight: bottomPanelHeight)
  }

  public func notifyContentOffsetDidChange() {
    delegate?.editorCoreContentOffsetDidChange(self)
  }

  public func notifyCompositionEnded(selectedLineColumn: LineColumnInfo) {
    delegate?.editorCoreCompositionEnded(self, selectedLineColumn: selectedLineColumn)
  }

  public func notifyLinkClicked(link: String) {
    delegate?.editorCoreLinkClicked(self, link: link)
  }
}
