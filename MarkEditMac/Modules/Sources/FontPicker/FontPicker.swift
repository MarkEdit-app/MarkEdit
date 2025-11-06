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
    let selectedFontName = configuration.localizedInfo(
      style: selectedFontStyle,
      size: selectedFontSize
    )

    HStack {
      ZStack {
        // Just to steal the bezel UI from TextField
        TextField(text: .constant("")) {}
          .focusable(false)
          .allowsHitTesting(false)
          .accessibilityHidden(true)

        Text(selectedFontName)
          .font(Font(selectedFontStyle.fontWith(size: 12)))
          .padding(.horizontal, 5)
          .truncationMode(.middle)
          .help(selectedFontName)
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

      ZStack(alignment: .bottomLeading) {
        IdentifiableWrapper()
          .frame(width: 1, height: 1)

        Menu {
          systemFontButton(
            style: .systemDefault,
            name: configuration.defaultFontName,
            design: .default
          )

          systemFontButton(
            style: .systemMono,
            name: configuration.monoFontName,
            design: .monospaced
          )

          systemFontButton(
            style: .systemRounded,
            name: configuration.roundedFontName,
            design: .rounded
          )

          systemFontButton(
            style: .systemSerif,
            name: configuration.serifFontName,
            design: .serif
          )

          Divider()

          Button(configuration.moreFontsItemTitle) {
            presentFontMenu()
          }

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

  func systemFontButton(style: FontStyle, name: String, design: Font.Design) -> some View {
    Button {
      changeFontStyle(style)
    } label: {
      Text(name).font(.system(.body, design: design))
    }
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

  @MainActor
  func presentFontMenu() {
    guard let contentView = NSApp.keyWindow?.contentView else {
      return
    }

    guard let sourceView = (contentView.firstDescendant { $0 is IdentifiableView }) else {
      return
    }

    let menu = NSMenu()
    let fontSize = NSFont.systemFontSize
    let textColor = NSColor.labelColor

    for fontFamily in NSFontManager.shared.availableFontFamilies {
      let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont(name: fontFamily, size: fontSize) ?? .systemFont(ofSize: fontSize),
        .foregroundColor: textColor,
      ]

      menu.addItem(withTitle: fontFamily) {
        changeFontStyle(.customFont(name: fontFamily))
      }.attributedTitle = NSAttributedString(
        string: fontFamily,
        attributes: attributes
      )
    }

    let location = CGPoint(x: configuration.modernStyle ? -4 : 0, y: sourceView.frame.height - 10)
    menu.popUp(positioning: nil, at: location, in: sourceView)
  }
}

private class IdentifiableView: NSView {}
private struct IdentifiableWrapper: NSViewRepresentable {
  func makeNSView(context: Context) -> NSView { IdentifiableView() }
  func updateNSView(_ nsView: NSView, context: Context) {}
}
