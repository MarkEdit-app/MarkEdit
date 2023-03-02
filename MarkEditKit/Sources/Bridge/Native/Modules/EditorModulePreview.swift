//
//  EditorModulePreview.swift
//  
//  Created by cyan on 1/7/23.
//

import Foundation

public protocol EditorModulePreviewDelegate: AnyObject {
  func editorPreview(_ sender: NativeModulePreview, show code: String, type: PreviewType, rect: CGRect)
}

public final class EditorModulePreview: NativeModulePreview {
  private weak var delegate: EditorModulePreviewDelegate?

  public init(delegate: EditorModulePreviewDelegate) {
    self.delegate = delegate
  }

  public func show(code: String, type: PreviewType, rect: JSRect) {
    delegate?.editorPreview(self, show: code, type: type, rect: rect.cgRect)
  }
}
