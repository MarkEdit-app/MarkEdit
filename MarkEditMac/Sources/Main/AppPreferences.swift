//
//  AppPreferences.swift
//  MarkEditMac
//
//  Created by cyan on 12/25/22.
//

import AppKit
import MarkEditCore
import MarkEditKit
import FontPicker

/**
 UserDefaults wrapper with handy getters and setters.
 */
enum AppPreferences {
  enum General {
    @Storage(key: "general.appearance", defaultValue: .system)
    static var appearance: Appearance

    @Storage(key: "general.new-window-behavior", defaultValue: .openDocument)
    static var newWindowBehavior: NewWindowBehavior

    @Storage(key: "general.default-text-encoding", defaultValue: .utf8)
    static var defaultTextEncoding: EditorTextEncoding

    @Storage(key: "general.default-line-endings", defaultValue: .lf)
    static var defaultLineEndings: LineEndings {
      didSet {
        performUpdates { $0.setDefaultLineBreak(defaultLineEndings.characters) }
      }
    }

    static var quitAlwaysKeepsWindows: Bool {
      get {
        UserDefaults.standard.bool(forKey: "NSQuitAlwaysKeepsWindows")
      }
      set {
        UserDefaults.standard.set(newValue, forKey: "NSQuitAlwaysKeepsWindows")
      }
    }
  }

  enum Editor {
    @Storage(key: "editor.light-theme", defaultValue: AppTheme.GitHubLight.editorTheme)
    static var lightTheme: String {
      didSet {
        AppTheme.current.updateAppearance()
      }
    }

    @Storage(key: "editor.dark-theme", defaultValue: AppTheme.GitHubDark.editorTheme)
    static var darkTheme: String {
      didSet {
        AppTheme.current.updateAppearance()
      }
    }

    @Storage(key: "editor.font-style", defaultValue: .systemMono)
    static var fontStyle: FontStyle {
      didSet {
        performUpdates { $0.setFontFamily(fontStyle.cssFontFamily) }
      }
    }

    @Storage(key: "editor.font-size", defaultValue: FontPicker.defaultFontSize)
    static var fontSize: Double {
      didSet {
        performUpdates { $0.setFontSize(fontSize) }
      }
    }

    @Storage(key: "editor.show-line-numbers", defaultValue: true)
    static var showLineNumbers: Bool {
      didSet {
        performUpdates { $0.setShowLineNumbers(enabled: showLineNumbers) }
      }
    }

    @Storage(key: "editor.show-active-line-indicator", defaultValue: true)
    static var showActiveLineIndicator: Bool {
      didSet {
        performUpdates { $0.setShowActiveLineIndicator(enabled: showActiveLineIndicator) }
      }
    }

    @Storage(key: "editor.show-selection-status", defaultValue: true)
    static var showSelectionStatus: Bool {
      didSet {
        performUpdates { $0.setShowSelectionStatus(enabled: showSelectionStatus) }
      }
    }

    @Storage(key: "editor.invisibles-behavior", defaultValue: .selection)
    static var invisiblesBehavior: EditorInvisiblesBehavior {
      didSet {
        performUpdates { $0.setInvisiblesBehavior(behavior: invisiblesBehavior) }
      }
    }

    @Storage(key: "editor.typewriter-mode", defaultValue: false)
    static var typewriterMode: Bool {
      didSet {
        performUpdates { $0.setTypewriterMode(enabled: typewriterMode) }
      }
    }

    @Storage(key: "editor.focus-mode", defaultValue: false)
    static var focusMode: Bool {
      didSet {
        performUpdates { $0.setFocusMode(enabled: focusMode) }
      }
    }

    @Storage(key: "editor.line-wrapping", defaultValue: true)
    static var lineWrapping: Bool {
      didSet {
        performUpdates { $0.setLineWrapping(enabled: lineWrapping) }
      }
    }

    @Storage(key: "editor.line-height", defaultValue: .normal)
    static var lineHeight: LineHeight {
      didSet {
        performUpdates { $0.setLineHeight(lineHeight.multiplier) }
      }
    }

    @Storage(key: "editor.tab-key-behavior", defaultValue: .insertTab)
    static var tabKeyBehavior: TabKeyBehavior {
      didSet {
        performUpdates { $0.setTabKeyBehavior(tabKeyBehavior) }
      }
    }

    @Storage(key: "editor.indent-unit", defaultValue: .twoSpaces)
    static var indentUnit: IndentUnit {
      didSet {
        performUpdates { $0.setIndentUnit(indentUnit) }
      }
    }
  }

  enum Assistant {
    @Storage(key: "assistant.words-in-document", defaultValue: true)
    static var wordsInDocument: Bool

    @Storage(key: "assistant.standard-words", defaultValue: true)
    static var standardWords: Bool

    @Storage(key: "assistant.guessed-words", defaultValue: false)
    static var guessedWords: Bool

    @Storage(key: "assistant.suggest-while-typing", defaultValue: false)
    static var suggestWhileTyping: Bool {
      didSet {
        performUpdates { $0.setSuggestWhileTyping(enabled: suggestWhileTyping) }
      }
    }
  }

  enum Search {
    @Storage(key: "search.case-sensitive", defaultValue: false)
    static var caseSensitive: Bool

    @Storage(key: "search.whole-word", defaultValue: false)
    static var wholeWord: Bool

    @Storage(key: "search.literal-search", defaultValue: false)
    static var literalSearch: Bool

    @Storage(key: "search.regular-expression", defaultValue: false)
    static var regularExpression: Bool
  }

  enum Window {
    @Storage(key: "window.toolbar-mode", defaultValue: .normal)
    static var toolbarMode: ToolbarMode {
      didSet {
        performUpdates { ($0.view.window as? EditorWindow)?.toolbarMode = toolbarMode }
      }
    }

    @Storage(key: "window.tabbing-mode", defaultValue: .automatic)
    static var tabbingMode: NSWindow.TabbingMode {
      didSet {
        performUpdates { $0.view.window?.tabbingMode = tabbingMode }
      }
    }

    @Storage(key: "window.reduce-transparency", defaultValue: false)
    static var reduceTransparency: Bool {
      didSet {
        performUpdates { ($0.view.window as? EditorWindow)?.reduceTransparency = reduceTransparency }
      }
    }
  }
}

extension AppPreferences {
  static var editorConfig: EditorConfig {
    EditorConfig(
      text: "",
      theme: AppTheme.current.editorTheme,
      fontFamily: Editor.fontStyle.cssFontFamily,
      fontSize: Editor.fontSize,
      showLineNumbers: Editor.showLineNumbers,
      showActiveLineIndicator: Editor.showActiveLineIndicator,
      invisiblesBehavior: Editor.invisiblesBehavior,
      typewriterMode: Editor.typewriterMode,
      focusMode: Editor.focusMode,
      lineWrapping: Editor.lineWrapping,
      lineHeight: Editor.lineHeight.multiplier,
      suggestWhileTyping: Assistant.suggestWhileTyping,
      defaultLineBreak: General.defaultLineEndings.characters,
      tabKeyBehavior: Editor.tabKeyBehavior.rawValue,
      indentUnit: Editor.indentUnit.characters,
      localizable: EditorLocalizable.main
    )
  }
}

// MARK: - Types

enum Appearance: Codable {
  case system
  case light
  case dark

  func resolved(with appearance: NSAppearance = NSApp.effectiveAppearance) -> NSAppearance? {
    switch self {
    case .system:
      return nil
    case .light:
      return NSAppearance(named: appearance.resolvedName(isDarkMode: false))
    case .dark:
      return NSAppearance(named: appearance.resolvedName(isDarkMode: true))
    }
  }
}

enum IndentUnit: Codable {
  case twoSpaces
  case fourSpaces
  case oneTab
  case twoTabs

  var characters: String {
    switch self {
    case .twoSpaces:
      return "  "
    case .fourSpaces:
      return "    "
    case .oneTab:
      return "\t"
    case .twoTabs:
      return "\t\t"
    }
  }
}

enum LineHeight: Codable {
  case tight
  case normal
  case relaxed

  var multiplier: Double {
    switch self {
    case .tight:
      return 1.2
    case .normal:
      return 1.5
    case .relaxed:
      return 1.8
    }
  }
}

enum NewWindowBehavior: Codable {
  case openDocument
  case newDocument
}

enum ToolbarMode: Codable {
  case normal
  case compact
  case hidden
}

extension NSWindow.TabbingMode: Codable {}

// MARK: - Private

private extension AppPreferences {
  static func performUpdates(action: (EditorViewController) -> Void) {
    EditorReusePool.shared.viewControllers().forEach { action($0) }
  }
}

@propertyWrapper
struct Storage<T: Codable> {
  private let key: String
  private let defaultValue: T

  init(key: String, defaultValue: T) {
    self.key = key
    self.defaultValue = defaultValue
  }

  var wrappedValue: T {
    get {
      guard let data = UserDefaults.standard.object(forKey: key) as? Data else {
        return defaultValue
      }

      let value = try? Coders.decoder.decode(T.self, from: data)
      return value ?? defaultValue
    }
    set {
      let data = try? Coders.encoder.encode(newValue)
      UserDefaults.standard.set(data, forKey: key)
    }
  }
}

private enum Coders {
  static let encoder = JSONEncoder()
  static let decoder = JSONDecoder()
}
