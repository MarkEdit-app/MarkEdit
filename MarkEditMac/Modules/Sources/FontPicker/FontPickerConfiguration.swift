//
//  FontPickerConfiguration.swift
//
//  Created by cyan on 1/29/23.
//

import AppKit
import CoreText

public struct FontPickerConfiguration {
  let selectedFontStyle: FontStyle
  let selectedFontSize: Double
  let selectButtonTitle: String
  let recentlyUsedItemTitle: String
  let moreFontsItemTitle: String
  let openPanelItemTitle: String
  let defaultFontName: String
  let monoFontName: String
  let roundedFontName: String
  let serifFontName: String

  public init(
    selectedFontStyle: FontStyle,
    selectedFontSize: Double,
    selectButtonTitle: String,
    recentlyUsedItemTitle: String,
    moreFontsItemTitle: String,
    openPanelItemTitle: String,
    defaultFontName: String,
    monoFontName: String,
    roundedFontName: String,
    serifFontName: String
  ) {
    self.selectedFontStyle = selectedFontStyle
    self.selectedFontSize = selectedFontSize
    self.selectButtonTitle = selectButtonTitle
    self.moreFontsItemTitle = moreFontsItemTitle
    self.openPanelItemTitle = openPanelItemTitle
    self.defaultFontName = defaultFontName
    self.recentlyUsedItemTitle = recentlyUsedItemTitle
    self.monoFontName = monoFontName
    self.roundedFontName = roundedFontName
    self.serifFontName = serifFontName
  }
}

extension FontPickerConfiguration {
  func localizedInfo(style: FontStyle, size: Double) -> String {
    let name = {
      switch style {
      case .systemDefault:
        return defaultFontName
      case .systemMono:
        return monoFontName
      case .systemRounded:
        return roundedFontName
      case .systemSerif:
        return serifFontName
      case let .customFont(name):
        return CTFontCopyDisplayName(CTFontCreateWithName(name as CFString, size, nil)) as String
      }
    }()

    return "\(name) - \(String(format: "%.1f", size))"
  }
}
