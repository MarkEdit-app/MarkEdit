//
//  FontPickerConfiguration.swift
//
//  Created by cyan on 1/29/23.
//

import AppKit

public struct FontPickerConfiguration {
  let selectedFontStyle: FontStyle
  let selectedFontSize: Double
  let selectButtonTitle: String
  let openPanelButtonTitle: String
  let defaultFontName: String
  let monoFontName: String
  let roundedFontName: String
  let serifFontName: String

  public init(selectedFontStyle: FontStyle, selectedFontSize: Double, selectButtonTitle: String, openPanelButtonTitle: String, defaultFontName: String, monoFontName: String, roundedFontName: String, serifFontName: String) {
    self.selectedFontStyle = selectedFontStyle
    self.selectedFontSize = selectedFontSize
    self.selectButtonTitle = selectButtonTitle
    self.openPanelButtonTitle = openPanelButtonTitle
    self.defaultFontName = defaultFontName
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
        return name
      }
    }()

    return "\(name) - \(String(format: "%.1f", size))"
  }
}
