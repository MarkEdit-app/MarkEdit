//
//  EditorModuleCore.swift
//
//  Created by cyan on 12/24/22.
//

import Foundation

public protocol EditorModuleCoreDelegate: AnyObject {
  func editorModuleCoreWindowDidLoad(_ sender: EditorModuleCore)
  func editorModuleCoreTextDidChange(_ sender: EditorModuleCore)
  func editorModuleCore(_ sender: EditorModuleCore, selectionDidChange lineColumn: LineColumnInfo)
}

public final class EditorModuleCore: NativeModuleCore {
  private weak var delegate: EditorModuleCoreDelegate?

  public init(delegate: EditorModuleCoreDelegate) {
    self.delegate = delegate
  }

  public func notifyWindowDidLoad() {
    delegate?.editorModuleCoreWindowDidLoad(self)
  }

  public func notifyTextDidChange() {
    delegate?.editorModuleCoreTextDidChange(self)
  }

  public func notifySelectionDidChange(lineColumn: LineColumnInfo) {
    delegate?.editorModuleCore(self, selectionDidChange: lineColumn)
  }
}
