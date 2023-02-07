//
//  FontPickerHandlers.swift
//  
//  Created by cyan on 1/30/23.
//

import Foundation

public struct FontPickerHandlers {
  let fontStyleDidChange: (FontStyle) -> Void
  let fontSizeDidChange: (Double) -> Void

  public init(fontStyleDidChange: @escaping (FontStyle) -> Void, fontSizeDidChange: @escaping (Double) -> Void) {
    self.fontStyleDidChange = fontStyleDidChange
    self.fontSizeDidChange = fontSizeDidChange
  }
}
