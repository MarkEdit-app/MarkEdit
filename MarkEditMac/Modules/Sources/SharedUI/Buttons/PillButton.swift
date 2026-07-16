//
//  PillButton.swift
//
//  Created by cyan on 7/15/26.
//

import SwiftUI

/// Capsule-shaped button in App Store style, either a filled or a bordered pill.
public struct PillButton: View {
  public enum Style {
    /// Filled accent capsule with a white title, like the App Store "Install" button.
    case prominent
    /// Bordered capsule with an accent-colored title.
    case bordered
  }

  private let title: String
  private let style: Style
  private let action: () -> Void

  public init(_ title: String, style: Style, action: @escaping () -> Void) {
    self.title = title
    self.style = style
    self.action = action
  }

  public var body: some View {
    switch style {
    case .prominent:
      Button(action: action) { label }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
    case .bordered:
      Button(action: action) { label.foregroundStyle(Color.accentColor) }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
    }
  }
}

// MARK: - Private

private extension PillButton {
  enum Constants {
    /// Shared minimum width so pills look neat; longer titles still grow to fit.
    static let minWidth: Double = 40
  }

  var label: some View {
    Text(title)
      .fontWeight(.semibold)
      .lineLimit(1)
      .frame(minWidth: Constants.minWidth)
  }
}
