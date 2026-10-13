//
//  EditorSettingsView.swift
//  MarkEditMac
//
//  Created by cyan on 1/26/23.
//

import AppKit
import AppKitExtensions
import SwiftUI
import FontPicker
import SettingsUI
import SharedUI
import ExtensionCore
import MarkEditCore
import MarkEditKit

@MainActor
struct EditorSettingsView: View {
  @State private var lightTheme = AppPreferences.Editor.lightTheme
  @State private var darkTheme = AppPreferences.Editor.darkTheme
  @State private var showLineNumbers = AppPreferences.Editor.showLineNumbers
  @State private var showActiveLineIndicator = AppPreferences.Editor.showActiveLineIndicator
  @State private var showSelectionStatus = AppPreferences.Editor.showSelectionStatus
  @State private var invisiblesBehavior = AppPreferences.Editor.invisiblesBehavior
  @State private var typewriterMode = AppPreferences.Editor.typewriterMode
  @State private var focusMode = AppPreferences.Editor.focusMode
  @State private var lineWrapping = AppPreferences.Editor.lineWrapping
  @State private var lineHeight = AppPreferences.Editor.lineHeight
  @State private var tabKeyBehavior = AppPreferences.Editor.tabKeyBehavior
  @State private var indentUnit = AppPreferences.Editor.indentUnit
  @State private var extensionsModel = ExtensionsModel()

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text(Localized.Settings.font)
        FontPicker(configuration: fontPickerConfiguration, handlers: fontPickerHandlers)
      }

      Divider()

      SettingsForm {
        Section {
          Picker(Localized.Settings.lightTheme, selection: $lightTheme) {
            createThemePicker(isDarkMode: false)
          }
          .onChange(of: lightTheme) {
            if let target = extensionTarget(for: lightTheme) {
              showExtensions(target: target, selection: $lightTheme, revertTo: AppPreferences.Editor.lightTheme)
            } else {
              AppPreferences.Editor.lightTheme = lightTheme
            }
          }
          .formMenuPicker()

          Picker(Localized.Settings.darkTheme, selection: $darkTheme) {
            createThemePicker(isDarkMode: true)
          }
          .onChange(of: darkTheme) {
            if let target = extensionTarget(for: darkTheme) {
              showExtensions(target: target, selection: $darkTheme, revertTo: AppPreferences.Editor.darkTheme)
            } else {
              AppPreferences.Editor.darkTheme = darkTheme
            }
          }
          .formMenuPicker()
        }

        Section {
          VStack(alignment: .leading) {
            Toggle(isOn: $showLineNumbers) {
              Text(Localized.Settings.lineNumbers)
            }
            .onChange(of: showLineNumbers) {
              AppPreferences.Editor.showLineNumbers = showLineNumbers
            }

            Toggle(isOn: $showActiveLineIndicator) {
              Text(Localized.Settings.activeLineIndicator)
            }
            .onChange(of: showActiveLineIndicator) {
              AppPreferences.Editor.showActiveLineIndicator = showActiveLineIndicator
            }

            Toggle(isOn: $showSelectionStatus) {
              Text(Localized.Settings.selectionStatus)
            }
            .onChange(of: showSelectionStatus) {
              AppPreferences.Editor.showSelectionStatus = showSelectionStatus
            }
          }
          .formLabel(alignment: .top, Localized.Settings.displayOptions)

          Picker(Localized.Settings.renderInvisibles, selection: $invisiblesBehavior) {
            Text(Localized.Settings.never).tag(EditorInvisiblesBehavior.never)
            Text(Localized.Settings.selection).tag(EditorInvisiblesBehavior.selection)
            Text(Localized.Settings.trailing).tag(EditorInvisiblesBehavior.trailing)
            Text(Localized.Settings.always).tag(EditorInvisiblesBehavior.always)
          }
          .onChange(of: invisiblesBehavior) {
            AppPreferences.Editor.invisiblesBehavior = invisiblesBehavior
          }
          .formMenuPicker()
        }

        Section {
          VStack(alignment: .leading) {
            Toggle(isOn: $typewriterMode) {
              Text(Localized.Settings.typewriterModeTitle)
            }
            .onChange(of: typewriterMode) {
              AppPreferences.Editor.typewriterMode = typewriterMode
            }

            Toggle(isOn: $focusMode) {
              Text(Localized.Settings.focusModeTitle)
            }
            .onChange(of: focusMode) {
              AppPreferences.Editor.focusMode = focusMode
            }
          }
          .formLabel(alignment: .top, Localized.Settings.editBehavior)

          Toggle(isOn: $lineWrapping) {
            Text(Localized.Settings.lineWrappingDescription)
          }
          .onChange(of: lineWrapping) {
            AppPreferences.Editor.lineWrapping = lineWrapping
          }
          .formLabel(Localized.Settings.lineWrappingLabel)
          .formBreathingInset()

          Picker(Localized.Settings.lineHeight, selection: $lineHeight) {
            Text(Localized.Settings.tightHeight).tag(LineHeight.tight)
            Text(Localized.Settings.normalHeight).tag(LineHeight.normal)
            Text(Localized.Settings.relaxedHeight).tag(LineHeight.relaxed)
          }
          .onChange(of: lineHeight) {
            AppPreferences.Editor.lineHeight = lineHeight
          }
          .formHorizontalRadio()
          .formBreathingInset()
        }

        Section {
          Picker(Localized.Settings.tabKeyBehavior, selection: $tabKeyBehavior) {
            Text(Localized.Settings.insertsTab).tag(TabKeyBehavior.insertTab)
            Text(Localized.Settings.insertsTwoSpaces).tag(TabKeyBehavior.insertTwoSpaces)
            Text(Localized.Settings.insertsFourSpaces).tag(TabKeyBehavior.insertFourSpaces)
            Text(Localized.Settings.indentsMore).tag(TabKeyBehavior.indentMore)
          }
          .onChange(of: tabKeyBehavior) {
            AppPreferences.Editor.tabKeyBehavior = tabKeyBehavior
          }
          .formMenuPicker()

          Picker(Localized.Settings.indentUnit, selection: $indentUnit) {
            Text(Localized.Settings.twoSpaces).tag(IndentUnit.twoSpaces)
            Text(Localized.Settings.fourSpaces).tag(IndentUnit.fourSpaces)
            Text(Localized.Settings.oneTab).tag(IndentUnit.oneTab)
            Text(Localized.Settings.twoTabs).tag(IndentUnit.twoTabs)
          }
          .onChange(of: indentUnit) {
            AppPreferences.Editor.indentUnit = indentUnit
          }
          .formMenuPicker()
        }
      }
    }
    .onAppear {
      extensionsModel.primeFromCache()
    }
    .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
      extensionsModel.primeFromCache()
    }
  }
}

// MARK: - Private

private extension EditorSettingsView {
  enum Constants {
    static let manageThemesTag = "$manageThemes"
    static let themeExtensionTagPrefix = "$themeExtension:"
  }

  var fontPickerConfiguration: FontPickerConfiguration {
    FontPickerConfiguration(
      selectedFontStyle: AppPreferences.Editor.fontStyle,
      selectedFontSize: AppPreferences.Editor.fontSize,
      selectButtonTitle: Localized.Settings.selectFont,
      recentlyUsedItemTitle: Localized.Settings.recentlyUsed,
      moreFontsItemTitle: Localized.Settings.moreFonts,
      openPanelItemTitle: Localized.Settings.openFontPanel,
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

  @ViewBuilder
  func createThemePicker(isDarkMode: Bool) -> some View {
    Section(Localized.Settings.lightThemes) {
      createThemePicker(isDark: false)
    }

    Section(Localized.Settings.darkThemes) {
      createThemePicker(isDark: true)
    }

    Section(Localized.Settings.themeExtensions) {
      ForEach(extensionsModel.installedThemes.filter(\.isEnabled)) { theme in
        Label {
          Text(theme.name.hasSuffix(" Theme") ? String(theme.name.dropLast(" Theme".count)) : theme.name)
        } icon: {
          if let image = themePatternImage(theme, isDarkMode: isDarkMode) {
            Image(nsImage: image)
              .renderingMode(.original)
              .accessibilityHidden(true)
          }
        }
        .labelStyle(.titleAndIcon)
        .tag(Constants.themeExtensionTagPrefix + theme.id)
      }

      Text(Localized.Settings.manageThemes)
        .tag(Constants.manageThemesTag)
    }
  }

  func createThemePicker(isDark: Bool) -> some View {
    ForEach(AppTheme.allCases.filter { $0.isDark == isDark }, id: \.self) { theme in
      Label {
        Text(theme.displayName)
      } icon: {
        Image(nsImage: theme.patternImage)
          .renderingMode(.original)
          .accessibilityHidden(true)
      }
      .labelStyle(.titleAndIcon)
      .tag(theme.editorTheme)
    }
  }

  func themePatternImage(_ theme: ExtensionsModel.Item, isDarkMode: Bool) -> NSImage? {
    guard let patterns = theme.colorPatterns, !patterns.isEmpty else {
      return nil
    }

    let index = theme.colorScheme == .both && isDarkMode && patterns.count >= 2 ? 1 : 0
    let colors = patterns[index]
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }
      .map { color in
        if color.hasPrefix("#"), color.count == 4 {
          return "#" + color.dropFirst().map { String(repeating: String($0), count: 2) }.joined()
        }
        return color
      }

    guard !colors.isEmpty else {
      return nil
    }

    guard colors.allSatisfy({ $0.hasPrefix("#") && $0.count == 7 && UInt32($0.dropFirst(), radix: 16) != nil }) else {
      Logger.log(.error, "Invalid color pattern for theme extension \(theme.id)")
      return nil
    }

    let isDark = theme.colorScheme == .dark || (theme.colorScheme == .both && index == 1)
    return AppTheme.patternImage(colorPattern: colors, isDark: isDark)
  }

  func extensionTarget(for selection: String) -> ExtensionsScrollTarget? {
    if selection == Constants.manageThemesTag {
      if let theme = extensionsModel.installedThemes.first(where: \.isEnabled) {
        return .item(id: theme.id, highlight: false)
      }

      return .category(.theme)
    }

    guard selection.hasPrefix(Constants.themeExtensionTagPrefix) else {
      return nil
    }

    return .item(id: String(selection.dropFirst(Constants.themeExtensionTagPrefix.count)))
  }

  func showExtensions(target: ExtensionsScrollTarget, selection: Binding<String>, revertTo value: String) {
    ExtensionsWindowController.shared.present(mode: .installed, scrollTo: target)
    NSApp.windows.forEach {
      if $0.contentViewController is SettingsRootViewController {
        $0.close()
      }
    }

    // In macOS Tahoe, this requires a delay to work
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      selection.wrappedValue = value
    }
  }
}
