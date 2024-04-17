//
//  TextCompletionLocalizable.swift
//
//  Created by cyan on 3/4/23.
//

import Foundation

public struct TextCompletionLocalizable: Sendable {
  let selectedHint: String

  public init(selectedHint: String) {
    self.selectedHint = selectedHint
  }
}
