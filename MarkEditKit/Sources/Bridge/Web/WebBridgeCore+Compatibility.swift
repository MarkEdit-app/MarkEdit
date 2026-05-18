//
//  WebBridgeCore+Compatibility.swift
//  MarkEditKit
//
//  Created by cyan on 5/18/26.
//

import MarkEditCore

@MainActor
public extension WebBridgeCore {
  func resetEditor(text: String, selectionRange: SelectionRange?) async throws -> Bool {
    try await resetEditor(text: text, selectionRange: selectionRange, preserveScrollPosition: nil)
  }
}
