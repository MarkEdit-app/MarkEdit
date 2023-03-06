//
//  LegacyTextFieldBezel.swift
//
//  Created by cyan on 3/6/23.
//

import AppKit
import SwiftUI

/**
 Just to steal the bezel UI from TextField,
 we could have used SwiftUI.TextField if "focusable" worked well on Monterey.
 */
struct LegacyTextFieldBezel: NSViewRepresentable {
  func makeNSView(context: Context) -> NSTextField {
    let textField = NSTextField()
    textField.focusRingType = .none
    textField.isBezeled = true
    textField.isEditable = false
    textField.isSelectable = false

    return textField
  }

  func updateNSView(_ nsView: NSTextField, context: Context) {
    // no-op
  }
}
