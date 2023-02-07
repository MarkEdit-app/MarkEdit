//
//  EditorSettingsView.swift
//  MarkEditMac
//
//  Created by cyan on 1/26/23.
//

import AppKit
import SwiftUI
import FontPicker
import SettingsUI
import MarkEditKit

struct EditorSettingsView: View {
  @State private var lightTheme = AppPreferences.Editor.lightTheme
  @State private var darkTheme = AppPreferences.Editor.darkTheme
  @State private var showLineNumbers = AppPreferences.Editor.showLineNumbers
  @State private var showActiveLineIndicator = AppPreferences.Editor.showActiveLineIndicator
  @State private var showInvisibles = AppPreferences.Editor.showInvisibles
  @State private var showSelectionStatus = AppPreferences.Editor.showSelectionStatus
  @State private var typewriterMode = AppPreferences.Editor.typewriterMode
  @State private var focusMode = AppPreferences.Editor.focusMode
  @State private var lineWrapping = AppPreferences.Editor.lineWrapping
  @State private var lineHeight = AppPreferences.Editor.lineHeight
  @State private var tabKeyBehavior = AppPreferences.Editor.tabKeyBehavior
  @State private var indentUnit = AppPreferences.Editor.indentUnit

  var body: some View {
    VStack(spacing: 0) {
      FontPicker(configuration: fontPickerConfiguration, handlers: fontPickerHandlers)
        .formLabel(Localized.Settings.font)

      Divider()

      SettingsForm {
        Section {
          Picker(Localized.Settings.lightTheme, selection: $lightTheme) {
            ForEach(AppTheme.allCases, id: \.self) {
              Text($0.description).tag($0.editorTheme)
            }
          }
          .onChange(of: lightTheme) {
            AppPreferences.Editor.lightTheme = $0
          }
          .formMenuPicker()

          Picker(Localized.Settings.darkTheme, selection: $darkTheme) {
            ForEach(AppTheme.allCases, id: \.self) {
              Text($0.description).tag($0.editorTheme)
            }
          }
          .onChange(of: darkTheme) {
            AppPreferences.Editor.darkTheme = $0
          }
          .formMenuPicker()
        }

        Section {
          VStack(alignment: .leading) {
            Toggle(isOn: $showLineNumbers) {
              Text(Localized.Settings.lineNumbers)
            }
            .onChange(of: showLineNumbers) {
              AppPreferences.Editor.showLineNumbers = $0
            }

            Toggle(isOn: $showActiveLineIndicator) {
              Text(Localized.Settings.activeLineIndicator)
            }
            .onChange(of: showActiveLineIndicator) {
              AppPreferences.Editor.showActiveLineIndicator = $0
            }

            Toggle(isOn: $showInvisibles) {
              Text(Localized.Settings.invisibleCharacters)
            }
            .onChange(of: showInvisibles) {
              AppPreferences.Editor.showInvisibles = $0
            }

            Toggle(isOn: $showSelectionStatus) {
              Text(Localized.Settings.selectionStatus)
            }
            .onChange(of: showSelectionStatus) {
              AppPreferences.Editor.showSelectionStatus = $0
            }
          }
          .formLabel(alignment: .top, Localized.Settings.displayOptions)
        }

        Section {
          VStack(alignment: .leading) {
            Toggle(isOn: $typewriterMode) {
              Text(Localized.Settings.typewriterModeTitle)
            }
            .onChange(of: typewriterMode) {
              AppPreferences.Editor.typewriterMode = $0
            }

            Toggle(isOn: $focusMode) {
              Text(Localized.Settings.focusModeTitle)
            }
            .onChange(of: focusMode) {
              AppPreferences.Editor.focusMode = $0
            }
          }
          .formLabel(alignment: .top, Localized.Settings.editBehavior)

          Toggle(isOn: $lineWrapping) {
            Text(Localized.Settings.lineWrappingDescription)
          }
          .onChange(of: lineWrapping) {
            AppPreferences.Editor.lineWrapping = $0
          }
          .formLabel(Localized.Settings.lineWrappingLabel)

          Picker(Localized.Settings.lineHeight, selection: $lineHeight) {
            Text(Localized.Settings.tightHeight).tag(LineHeight.tight)
            Text(Localized.Settings.normalHeight).tag(LineHeight.normal)
            Text(Localized.Settings.relaxedHeight).tag(LineHeight.relaxed)
          }
          .onChange(of: lineHeight) {
            AppPreferences.Editor.lineHeight = $0
          }
          .formHorizontalRadio()
        }

        Section {
          Picker(Localized.Settings.tabKeyBehavior, selection: $tabKeyBehavior) {
            Text(Localized.Settings.insertsTab).tag(TabKeyBehavior.insertTab)
            Text(Localized.Settings.insertsTwoSpaces).tag(TabKeyBehavior.insertTwoSpaces)
            Text(Localized.Settings.insertsFourSpaces).tag(TabKeyBehavior.insertFourSpaces)
          }
          .onChange(of: tabKeyBehavior) {
            AppPreferences.Editor.tabKeyBehavior = $0
          }
          .formMenuPicker()

          Picker(Localized.Settings.indentUnit, selection: $indentUnit) {
            Text(Localized.Settings.twoSpaces).tag(IndentUnit.twoSpaces)
            Text(Localized.Settings.fourSpaces).tag(IndentUnit.fourSpaces)
            Text(Localized.Settings.oneTab).tag(IndentUnit.oneTab)
            Text(Localized.Settings.twoTabs).tag(IndentUnit.twoTabs)
          }
          .onChange(of: indentUnit) {
            AppPreferences.Editor.indentUnit = $0
          }
          .formMenuPicker()
        }
      }
    }
  }
}

// MARK: - Private

private extension EditorSettingsView {
  var fontPickerConfiguration: FontPickerConfiguration {
    FontPickerConfiguration(
      selectedFontStyle: AppPreferences.Editor.fontStyle,
      selectedFontSize: AppPreferences.Editor.fontSize,
      selectButtonTitle: Localized.Settings.selectFont,
      openPanelButtonTitle: Localized.Settings.openFontPanel,
      defaultFontName: Localized.Settings.systemDefault,
      monoFontName: Localized.Settings.systemMono,
      roundedFontName: Localized.Settings.systemRounded,
      serifFontName: Localized.Settings.systemSerif
    )
  }

  var fontPickerHandlers: FontPickerHandlers {
    FontPickerHandlers(
      fontStyleDidChange: { fontStyle in
        AppPreferences.Editor.fontStyle = fontStyle
      },
      fontSizeDidChange: { fontSize in
        AppPreferences.Editor.fontSize = fontSize
      }
    )
  }
}
