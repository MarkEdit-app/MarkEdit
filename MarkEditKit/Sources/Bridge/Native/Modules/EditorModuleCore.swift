//
//  EditorModuleCore.swift
//
//  Created by cyan on 12/24/22.
//

import Foundation

public protocol EditorModuleCoreDelegate: AnyObject {
  func editorCoreWindowDidLoad(_ sender: EditorModuleCore)
  func editorCoreTextDidChange(_ sender: EditorModuleCore)
  func editorCore(_ sender: EditorModuleCore, selectionDidChange lineColumn: LineColumnInfo)
}

public final class EditorModuleCore: NativeModuleCore {
  private weak var delegate: EditorModuleCoreDelegate?

  public init(delegate: EditorModuleCoreDelegate) {
    self.delegate = delegate
  }

  public func notifyWindowDidLoad() {
    delegate?.editorCoreWindowDidLoad(self)
  }

  public func notifyTextDidChange() {
    delegate?.editorCoreTextDidChange(self)
  }

  public func notifySelectionDidChange(lineColumn: LineColumnInfo) {
    delegate?.editorCore(self, selectionDidChange: lineColumn)
  }
}
