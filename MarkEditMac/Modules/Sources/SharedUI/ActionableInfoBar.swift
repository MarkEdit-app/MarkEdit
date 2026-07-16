//
//  ActionableInfoBar.swift
//
//  Created by cyan on 7/16/26.
//

import SwiftUI

/// Material-backed bottom information bar with action and an optional symbol.
public struct ActionableInfoBar<Action: View>: View {
  private let message: String
  private let systemImage: String?
  private let iconColor: Color
  private let action: () -> Action

  public init(
    message: String,
    systemImage: String? = nil,
    iconColor: Color = .secondary,
    @ViewBuilder action: @escaping () -> Action
  ) {
    self.message = message
    self.systemImage = systemImage
    self.iconColor = iconColor
    self.action = action
  }

  public var body: some View {
    VStack(spacing: 0) {
      Divider()

      HStack(spacing: 6) {
        if let systemImage {
          Image(systemName: systemImage)
            .foregroundStyle(iconColor)
        }

        Text(message)
          .font(.body)

        Spacer()

        action()
          .environment(\.controlActiveState, .active) // Always active style
      }
      .padding(16)
    }
    .background(.bar)
  }
}
