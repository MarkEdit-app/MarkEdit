//
//  EditorDocument+Scripting.swift
//  MarkEdit
//
//  Created by Steven Kaplan on 4/2/25.
//

extension EditorDocument {
  @objc func source() -> String {
    return self.stringValue
  }

  @objc func setSource (_ newValue: String) {
    if newValue != self.stringValue {
      let currentEditor = self.windowControllers.first?.contentViewController as? EditorViewController
      currentEditor?.bridge.core.replaceText(text: newValue, granularity: .wholeDocument)
    }
  }
}
