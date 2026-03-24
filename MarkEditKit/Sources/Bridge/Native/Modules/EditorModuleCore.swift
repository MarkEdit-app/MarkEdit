//
//  EditorModuleCore.swift
//
//  Created by cyan on 12/24/22.
//

import CoreGraphics
import Foundation

public enum WindowResizeMethod {
  case to(CGSize)
  case by(CGSize)
}

public enum WindowMoveMethod {
  case to(CGPoint)
  case by(CGPoint)
}

@MainActor
public protocol EditorModuleCoreDelegate: AnyObject {
  func editorCoreWindowDidLoad(_ sender: EditorModuleCore)
  func editorCoreWindowResize(_ sender: EditorModuleCore, method: WindowResizeMethod)
  func editorCoreWindowMove(_ sender: EditorModuleCore, method: WindowMoveMethod)
  func editorCoreWindowClose(_ sender: EditorModuleCore)
  func editorCoreEditorDidBecomeIdle(_ sender: EditorModuleCore)
  func editorCoreBackgroundColorDidChange(_ sender: EditorModuleCore, color: UInt32, alpha: Double)
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

  public func notifyWindowResizeTo(width: Double, height: Double) {
    delegate?.editorCoreWindowResize(self, method: .to(CGSize(width: width, height: height)))
  }

  public func notifyWindowResizeBy(x: Double, y: Double) {
    delegate?.editorCoreWindowResize(self, method: .by(CGSize(width: x, height: y)))
  }

  public func notifyWindowMoveTo(x: Double, y: Double) {
    delegate?.editorCoreWindowMove(self, method: .to(CGPoint(x: x, y: y)))
  }

  public func notifyWindowMoveBy(x: Double, y: Double) {
    delegate?.editorCoreWindowMove(self, method: .by(CGPoint(x: x, y: y)))
  }

  public func notifyWindowClose() {
    delegate?.editorCoreWindowClose(self)
  }

  public func notifyEditorDidBecomeIdle() {
    delegate?.editorCoreEditorDidBecomeIdle(self)
  }

  public func notifyBackgroundColorDidChange(color: Int, alpha: Double) {
    delegate?.editorCoreBackgroundColorDidChange(self, color: UInt32(color), alpha: alpha)
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
