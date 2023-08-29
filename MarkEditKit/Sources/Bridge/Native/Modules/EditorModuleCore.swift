//
//  EditorModuleCore.swift
//
//  Created by cyan on 12/24/22.
//

import Foundation

public protocol EditorModuleCoreDelegate: AnyObject {
  func editorCoreWindowDidLoad(_ sender: EditorModuleCore)
  func editorCoreViewportScaleDidChange(_ sender: EditorModuleCore)
  func editorCoreViewDidUpdate(
    _ sender: EditorModuleCore,
    contentEdited: Bool,
    compositionEnded: Bool,
    isDirty: Bool,
    selectedLineColumn: LineColumnInfo
  )
  func editorCoreCompositionEnded(_ sender: EditorModuleCore, selectedLineColumn: LineColumnInfo)
}

public final class EditorModuleCore: NativeModuleCore {
  private weak var delegate: EditorModuleCoreDelegate?

  public init(delegate: EditorModuleCoreDelegate) {
    self.delegate = delegate
  }

  public func notifyWindowDidLoad() {
    delegate?.editorCoreWindowDidLoad(self)
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

  public func notifyCompositionEnded(selectedLineColumn: LineColumnInfo) {
    delegate?.editorCoreCompositionEnded(self, selectedLineColumn: selectedLineColumn)
  }
}
