//
//  View+Extension.swift
//
//  Created by cyan on 1/26/23.
//

import SwiftUI

/**
 View extension for form building.
 */
public extension View {
  func formLabel(alignment: VerticalAlignment = .center, _ text: String) -> some View {
    formLabel(alignment: alignment, Text(text))
  }

  func formLabel<V: View>(alignment: VerticalAlignment = .center, _ content: V) -> some View {
    HStack(alignment: alignment) {
      content
      self.frame(maxWidth: .infinity, alignment: .leading)
        .alignmentGuide(.controlAlignment) { $0[.leading] }
    }
    .alignmentGuide(.leading) { $0[.controlAlignment] }
  }

  func formMenuPicker() -> some View {
    pickerStyle(.menu).frame(minWidth: 280)
  }

  func formHorizontalRadio() -> some View {
    pickerStyle(.radioGroup).horizontalRadioGroupLayout()
  }
}

// MARK: - Private

private extension HorizontalAlignment {
  enum ControlAlignment: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
      return context[HorizontalAlignment.center]
    }
  }

  static let controlAlignment = HorizontalAlignment(ControlAlignment.self)
}
