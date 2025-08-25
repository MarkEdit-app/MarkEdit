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

  func formMenuPicker(minWidth: Double = 280) -> some View {
    pickerStyle(.menu).frame(minWidth: minWidth)
  }

  func formHorizontalRadio() -> some View {
    pickerStyle(.radioGroup).horizontalRadioGroupLayout()
  }

  func formDescription(fontSize: Double = 12) -> some View {
    font(.system(size: fontSize)).foregroundStyle(.secondary)
  }

  func formBreathingInset() -> some View {
    if #available(macOS 26.0, *) {
      // For unknown reasons, this is required to prevent extreme tight spacing
      return padding(.top, .ulpOfOne)
    }

    return self
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
