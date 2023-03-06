//
//  FontPicker.swift
//
//  Created by cyan on 1/29/23.
//

import AppKit
import SwiftUI

public struct FontPicker: View {
  public static let defaultFontSize: Double = 15
  public static let minimumFontSize: Double = 9
  public static let maximumFontSize: Double = 96

  private let configuration: FontPickerConfiguration
  private let handlers: FontPickerHandlers

  @State private var selectedFontStyle: FontStyle
  @State private var selectedFontSize: Double

  public init(configuration: FontPickerConfiguration, handlers: FontPickerHandlers) {
    self.configuration = configuration
    self.handlers = handlers
    self.selectedFontStyle = configuration.selectedFontStyle
    self.selectedFontSize = configuration.selectedFontSize
  }

  public var body: some View {
    HStack {
      ZStack {
        // Just to steal the bezel UI from TextField
        if #available(macOS 13.0, *) {
          TextField(text: .constant("")) {}
            .focusable(false) // Doesn't work on Monterey
            .allowsHitTesting(false)
        } else {
          LegacyTextFieldBezel()
        }

        Text(configuration.localizedInfo(style: selectedFontStyle, size: selectedFontSize))
          .font(Font(selectedFontStyle.fontWith(size: 12)))
          .padding(.horizontal, 5)
          .truncationMode(.middle)
      }
      .frame(width: 190, height: 19, alignment: .center)

      Stepper(
        value: $selectedFontSize,
        in: Self.minimumFontSize...Self.maximumFontSize,
        label: {},
        onEditingChanged: { _ in
          changeFontSize(selectedFontSize)
        }
      )

      Menu {
        Button(configuration.defaultFontName) {
          changeFontStyle(.systemDefault)
        }
        Button(configuration.monoFontName) {
          changeFontStyle(.systemMono)
        }
        Button(configuration.roundedFontName) {
          changeFontStyle(.systemRounded)
        }
        Button(configuration.serifFontName) {
          changeFontStyle(.systemSerif)
        }

        Divider()

        Button(configuration.openPanelButtonTitle) {
          FontManagerDelegate.shared.fontDidChange = { font in
            changeFontStyle(.customFont(name: font.fontName))
            changeFontSize(font.pointSize)
          }

          NSFontManager.shared.target = FontManagerDelegate.shared
          NSFontPanel.shared.setPanelFont(selectedFont, isMultiple: false)
          NSFontPanel.shared.orderBack(nil)
        }
      } label: {
        Text(configuration.selectButtonTitle)
      }
    }
    .padding(.vertical, 20)
    .onReceive(NotificationCenter.default.fontSizePublisher) {
      // Generally speaking, font size can also be changed by pressing ⌘ + ⌘ -, and ⌘ 0
      if let fontSize = $0.object as? Double {
        selectedFontSize = fontSize
      }
    }
  }
}

// MARK: - Private

private extension FontPicker {
  var selectedFont: NSFont {
    selectedFontStyle.fontWith(size: selectedFontSize)
  }

  func changeFontStyle(_ fontStyle: FontStyle) {
    selectedFontStyle = fontStyle
    handlers.fontStyleDidChange(fontStyle)
  }

  func changeFontSize(_ fontSize: Double) {
    guard fontSize >= Self.minimumFontSize && fontSize <= Self.maximumFontSize else {
      return NSSound.beep()
    }

    selectedFontSize = fontSize
    handlers.fontSizeDidChange(fontSize)
  }
}
