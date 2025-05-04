//
//  EditorModuleCore.swift
//
//  Created by cyan on 12/24/22.
//

import Foundation

@MainActor
public protocol EditorModuleCoreDelegate: AnyObject {
  func editorCoreWindowDidLoad(_ sender: EditorModuleCore)
  func editorCoreEditorDidBecomeIdle(_ sender: EditorModuleCore)
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
  func editorCoreLightWarning(_ sender: EditorModuleCore)
}

public final class EditorModuleCore: NativeModuleCore {
  private weak var delegate: EditorModuleCoreDelegate?

  public init(delegate: EditorModuleCoreDelegate) {
    self.delegate = delegate
  }

  public func notifyWindowDidLoad() {
    delegate?.editorCoreWindowDidLoad(self)
  }

  public func notifyEditorDidBecomeIdle() {
    delegate?.editorCoreEditorDidBecomeIdle(self)
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

  public func notifyLightWarning() {
    delegate?.editorCoreLightWarning(self)
  }
}
