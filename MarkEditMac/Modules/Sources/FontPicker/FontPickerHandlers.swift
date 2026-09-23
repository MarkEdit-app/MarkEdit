//
//  FontPickerHandlers.swift
//  
//  Created by cyan on 1/30/23.
//

import Foundation

@MainActor
public struct FontPickerHandlers {
  let fontStyleDidChange: @MainActor (FontStyle) -> Void
  let fontSizeDidChange: @MainActor (Double) -> Void

  public init(
    fontStyleDidChange: @escaping @MainActor (FontStyle) -> Void,
    fontSizeDidChange: @escaping @MainActor (Double) -> Void
  ) {
    self.fontStyleDidChange = fontStyleDidChange
    self.fontSizeDidChange = fontSizeDidChange
  }
}
