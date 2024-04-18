//
//  EditorModulePreview.swift
//  
//  Created by cyan on 1/7/23.
//

import Foundation
import MarkEditCore

@MainActor
public protocol EditorModulePreviewDelegate: AnyObject {
  func editorPreview(_ sender: NativeModulePreview, show code: String, type: PreviewType, rect: CGRect)
}

public final class EditorModulePreview: NativeModulePreview {
  private weak var delegate: EditorModulePreviewDelegate?

  public init(delegate: EditorModulePreviewDelegate) {
    self.delegate = delegate
  }

  public func show(code: String, type: PreviewType, rect: WebRect) {
    delegate?.editorPreview(self, show: code, type: type, rect: rect.cgRect)
  }
}
