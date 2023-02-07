//
//  EditorConfig+Extension.swift
//
//  Created by cyan on 12/23/22.
//

import Foundation

public extension EditorConfig {
  var toHtml: String {
    indexHtml?.replacingOccurrences(of: "\"{{EDITOR_CONFIG}}\"", with: jsonEncoded) ?? ""
  }
}

extension EditorConfig {
  /// index.html built by CoreEditor
  private var indexHtml: String? {
    guard let path = Bundle.main.url(forResource: "index", withExtension: "html") else {
      fatalError("Missing index.html to set up the editor")
    }

    return try? Data(contentsOf: path).toString()
  }
}
